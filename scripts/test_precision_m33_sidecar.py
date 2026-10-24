"""M3.3 sidecar contract tests; no BBA binaries or full Deal required."""
import io
import json
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path
from unittest.mock import patch

import precision_m33_sidecar as s

FIXTURE = {
    "version": 1, "profileId": s.PROFILE_ID, "revision": 1,
    "cardSha256": s.PINNED_SELECTED_CARD_SHA256,
    "opponentModel": "21GF", "seat": "N", "dealer": "N",
    "vul": "Both", "ctx": "", "hand": "AKQ3.KQ4.AJ3.KQ7",
}


class NativeContractTest(unittest.TestCase):
    def test_valid_opening_and_seat_rotation(self):
        record, auction = s.validate_request(FIXTURE)
        self.assertEqual(auction, [])
        self.assertEqual(record["seat"], "N")
        row = dict(FIXTURE, dealer="N", seat="E", ctx="1C")
        self.assertEqual(s.validate_request(row)[1], ["1C"])
        row = dict(FIXTURE, dealer="S", seat="W", ctx="1C")
        self.assertEqual(s.validate_request(row)[1], ["1C"])
        row = dict(FIXTURE, dealer="N", seat="S", ctx="1C-P")
        self.assertEqual(s.validate_request(row)[1], ["1C", "PASS"])

    def test_rejects_wrong_actor_invalid_hands_and_unauthorized_fields(self):
        for patch_fields in [
            {"seat":"E"}, {"profileId":"BA-SAYC"},
            {"revision":2}, {"cardSha256":"0"*64},
            {"opponentModel":"PRECISION"}, {"hand":"AAQ3.KQ4.AJ3.KQ7"},
            {"vul":"Unknown"}, {"ctx":"1C-P-P-P"},
            {"ctx":"P-P-P-P"}, {"ctx":"1C/2D"},
        ]:
            with self.subTest(patch_fields=patch_fields):
                with self.assertRaises(s.PrecisionProtocolError):
                    s.validate_request(dict(FIXTURE, **patch_fields))
        with self.assertRaises(s.PrecisionProtocolError):
            s.validate_request(dict(FIXTURE, completeDeal="SECRET"))
        with self.assertRaises(s.PrecisionProtocolError):
            s.validate_request(dict(FIXTURE, hand={"N":"full"}))

    def test_native_uses_own_meckwell_and_pinned_opponent_card(self):
        calls = []
        class StubBot:
            def __init__(self, *args):
                calls.append(args)
            def bid(self, auction):
                calls.append(tuple(auction))
                return type("R", (), {"bid": "1C"})()
        engine=object.__new__(s.NativePrecisionEngine)
        engine.precision_cc=Path("/vendor/Meckwell.bbsa")
        engine.opponent_cards={
            "21GF":Path("/vendor/BEN-21GF.bbsa"),
            "SAYC":Path("/vendor/BEN-SAYC.bbsa"),
        }
        engine._builder=StubBot
        result=engine.decide(FIXTURE)
        self.assertEqual(result["bid"], "1C")
        self.assertEqual(result["cardSha256"],s.PINNED_SELECTED_CARD_SHA256)
        self.assertEqual(calls[0][0],"/vendor/Meckwell.bbsa")
        self.assertEqual(calls[0][1],"/vendor/BEN-21GF.bbsa")
        self.assertEqual(calls[0][2:6],(0,FIXTURE["hand"],(True,True),0))
        self.assertEqual(calls[1],())
        calls.clear()
        engine.decide(dict(FIXTURE, opponentModel="SAYC"))
        self.assertEqual(calls[0][1],"/vendor/BEN-SAYC.bbsa")

    def test_http_loopback_post_and_failure_redaction(self):
        seen=[]
        def fake(payload):
            seen.append(payload)
            s.validate_request(payload)
            return {"bid":"1C","provider":s.PROVIDER,"revision":1,
                    "profileId":s.PROFILE_ID,
                    "cardSha256":s.PINNED_SELECTED_CARD_SHA256}
        server=s.LocalResearchServer(("127.0.0.1",0),s.handler_factory(fake))
        thread=threading.Thread(target=server.serve_forever,daemon=True)
        thread.start()
        try:
            base=f"http://127.0.0.1:{server.server_port}"
            req=urllib.request.Request(base+s.BID_ROUTE,
                data=json.dumps(FIXTURE).encode(),
                headers={"Content-Type":"application/json"},method="POST")
            with urllib.request.urlopen(req,timeout=3) as response:
                obj=json.load(response)
            self.assertEqual(obj["bid"],"1C")
            self.assertEqual(len(seen),1)
            self.assertNotIn("hand",obj)
            bad=dict(FIXTURE, opponentModel="COMPROMISED")
            req=urllib.request.Request(base+s.BID_ROUTE,
                data=json.dumps(bad).encode(),
                headers={"Content-Type":"application/json"},method="POST")
            with self.assertRaises(urllib.error.HTTPError) as err:
                urllib.request.urlopen(req,timeout=3)
            self.assertEqual(err.exception.code,400)
            self.assertNotIn(FIXTURE["hand"],err.exception.read().decode())
            with urllib.request.urlopen(base+s.HEALTH_ROUTE,timeout=3) as res:
                health=json.load(res)
            self.assertNotIn("hand",health)
            self.assertEqual(health["sourceCommit"],s.PINNED_BEN)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=3)

    def test_vendor_pin_fails_closed(self):
        with patch.object(s,"check_ben_source"),patch.object(
                s,"summarize_candidate",
                return_value={"cardSha256":"bad"}):
            with self.assertRaises(s.ResearchError):
                s.verify_vendor(Path("/tmp/untrusted"))


if __name__ == "__main__":
    unittest.main()

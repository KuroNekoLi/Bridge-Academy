"""M3.4 two-sided native BBA CC routing regression, no EPBot library required."""
import unittest
from pathlib import Path
from precision_m33_sidecar import (
  NativePrecisionEngine, PrecisionProtocolError,
  validate_table_request, PROFILE_ID, PINNED_SELECTED_CARD_SHA256,
)
BASE = {
  "version":1,"profileId":PROFILE_ID,"revision":1,
  "cardSha256":PINNED_SELECTED_CARD_SHA256,
  "northSouth":PROFILE_ID, "eastWest":"BA-SAYC",
  "dealer":"N","seat":"N","ctx":"","vul":"","hand":"AKQ3.KQ4.AJ3.KQ7",
}
class TableResearchTest(unittest.TestCase):
  def test_seat_turn_and_metadata(self):
    for seat,ctx in (("N",""),("E","1C"),("S","1C-P"),("W","1C-P-1D")):
      data=dict(BASE,seat=seat,ctx=ctx)
      self.assertEqual(validate_table_request(data)[0]["seat"],seat)
    with self.assertRaises(PrecisionProtocolError):
      validate_table_request(dict(BASE,seat="W"))

  def test_rejects_double_precision_and_false_model(self):
    for row in (
      dict(BASE,northSouth=PROFILE_ID,eastWest=PROFILE_ID),
      dict(BASE,northSouth="BA-21GF",eastWest="BA-SAYC"),
      dict(BASE,eastWest="BA-FAKE"),
      dict(BASE,cardSha256="bad"),
      dict(BASE,hand="N:AKQ3.KQ4.AJ3.KQ7"),
      dict(BASE,privateDeal="secret")
    ):
      with self.subTest(row=row),self.assertRaises(PrecisionProtocolError):
        validate_table_request(row)

  def test_both_sides_receive_own_convention_and_enemy_cc(self):
    calls=[]
    class FakeBot:
      def __init__(self,*args):
        calls.append(args)
      def bid(self,history):
        return type("R",(),{"bid":"PASS"})()
    engine=object.__new__(NativePrecisionEngine)
    engine.precision_cc=Path("/vendor/Meckwell.bbsa")
    engine.opponent_cards={
      "21GF":Path("/vendor/BEN-21GF.bbsa"),
      "SAYC":Path("/vendor/BEN-SAYC.bbsa"),
    }
    engine._builder=FakeBot
    a=engine.table_bid(BASE)
    self.assertEqual(a["bid"],"PASS")
    self.assertEqual(calls[0][0],"/vendor/Meckwell.bbsa")
    self.assertEqual(calls[0][1],"/vendor/BEN-SAYC.bbsa")
    calls.clear()
    b=engine.table_bid(dict(BASE,seat="E",ctx="1C"))
    self.assertEqual(b["bid"],"PASS")
    self.assertEqual(calls[0][0],"/vendor/BEN-SAYC.bbsa")
    self.assertEqual(calls[0][1],"/vendor/Meckwell.bbsa")
    self.assertEqual(calls[0][2],1)
    calls.clear()
    engine.table_bid(dict(BASE,northSouth="BA-21GF",
                         eastWest=PROFILE_ID,seat="E",ctx="1C"))
    self.assertEqual(calls[0][0],"/vendor/Meckwell.bbsa")
    self.assertEqual(calls[0][1],"/vendor/BEN-21GF.bbsa")

if __name__=="__main__":
  unittest.main()

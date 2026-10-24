#!/usr/bin/env python3
"""Real EPBot post-auction convention interpretation E2E; no deal leaks."""
import json
import urllib.error
import urllib.request
from precision_m33_sidecar import PINNED_SELECTED_CARD_SHA256, PROFILE_ID

def post(body,port):
    req=urllib.request.Request(
        f"http://127.0.0.1:{port}/v1/precision/auction-inference",
        method="POST",
        headers={"Content-Type":"application/json"},
        data=json.dumps(body).encode("utf-8"))
    try:
        with urllib.request.urlopen(req,timeout=30) as response:
            return response.status,json.load(response)
    except urllib.error.HTTPError as error:
        return error.code,json.loads(error.read())

def run(port):
    examples=[
        ("BA-PRECISION-MECKWELL","BA-SAYC","E","32.9843.J73.Q943"),
        ("BA-SAYC","BA-PRECISION-MECKWELL","S","QT6.AJ6.KT6.JT52"),
        ("BA-PRECISION-MECKWELL","BA-21GF","W","K9874.T52.Q54.A8"),
        ("BA-21GF","BA-PRECISION-MECKWELL","N","AJ5.KQ7.A982.K76"),
    ]
    for ns,ew,seat,hand in examples:
        request={
            "version":1,"profileId":PROFILE_ID,"revision":1,
            "cardSha256":PINNED_SELECTED_CARD_SHA256,
            "northSouth":ns,"eastWest":ew,"seat":seat,"dealer":"N",
            "vul":"","ctx":"3N-P-P-P","hand":hand,
        }
        status,obj=post(request,port)
        if status!=200:
            raise RuntimeError("Native BBA convention inference failed")
        assert obj["source"]=="BBA_AUCTION_ESTIMATE"
        assert obj["cardSha256"]==PINNED_SELECTED_CARD_SHA256
        assert len(obj)==6
        assert set(obj["suitEstimates"])==set("NESW")
        for values in obj["suitEstimates"].values():
            assert set(values)==set("CDHS")
            assert all(type(v)==int and 0<=v<=13 for v in values.values())
        assert "hand" not in obj and "deal" not in obj
    invalid={**request,"ctx":"3N-P-P"}
    status,obj=post(invalid,port)
    assert status==400 and obj=={"error":"invalid_request"}
    invalid={**request,"hiddenDeal":"never allowed"}
    status,obj=post(invalid,port)
    assert status==400 and obj=={"error":"invalid_request"}
    print("M36_NATIVE_BBA_CONVENTION_INFERENCE_PASS",
          json.dumps({"realNativeCases":len(examples),
                      "rejectedMalformed":2,
                      "ownerPrivateHandOnly":True,
                      "fullGameStrengthValidated":False}))

if __name__=="__main__":
    run(18088)

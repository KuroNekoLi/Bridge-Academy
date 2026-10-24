#!/usr/bin/env python3
"""Real pinned EPBot HTTP smoke: eight original openers + negative tests."""
from __future__ import annotations
import argparse
import json
import urllib.error
import urllib.request
from pathlib import Path
from precision_m33_sidecar import PINNED_SELECTED_CARD_SHA256, PROFILE_ID, REVISION

def post(origin, body):
    req=urllib.request.Request(
        origin+"/v1/precision/bid",
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type":"application/json"},
        method="POST")
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return r.status,json.load(r)
    except urllib.error.HTTPError as e:
        return e.code,json.loads(e.read())

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--port",type=int,default=18088)
    parser.add_argument("--fixtures",type=Path,default=Path(
        "scripts/fixtures/precision_m3_cases.json"))
    args=parser.parse_args()
    origin=f"http://127.0.0.1:{args.port}"
    with urllib.request.urlopen(origin+"/health",timeout=10) as r:
        info=json.load(r)
    assert info["cardSha256"]==PINNED_SELECTED_CARD_SHA256
    assert info["status"]=="research_ready"
    cases=json.loads(args.fixtures.read_text(encoding="utf-8"))
    strong=0
    for i,case in enumerate(cases):
        for opponent in ("21GF","SAYC"):
            request={
                "version":1,"profileId":PROFILE_ID,"revision":REVISION,
                "cardSha256":PINNED_SELECTED_CARD_SHA256,
                "opponentModel":opponent,"seat":"N","dealer":"N",
                "vul":"","ctx":"","hand":case["hand"],
            }
            status,result=post(origin,request)
            assert status==200,(case["id"],opponent,status)
            assert result["cardSha256"]==PINNED_SELECTED_CARD_SHA256
            assert result["provider"]=="BBA_NATIVE_EPBOT"
            if case["expectStrongClub"]:
                strong+=1
                assert result["bid"]=="1C",(case["id"],opponent,result["bid"])
            if i==0 and opponent=="21GF":
                negative=dict(request,cardSha256="forged")
                status,result=post(origin,negative)
                assert status==400 and result.get("error")=="invalid_request"
                negative=dict(request,opponentModel="PRECISION")
                status,result=post(origin,negative)
                assert status==400 and result.get("error")=="invalid_request"
                negative=dict(request,hand="AKQ3.KQ4.AJ3.KQ7",deal="SECRET")
                status,result=post(origin,negative)
                assert status==400 and "hand" not in json.dumps(result)
    # 8 fixtures * two known opponent descriptions; no full 52-card gameplay.
    print("M3_3_REAL_EPBOT_HTTP_PASS",
          "requests",len(cases)*2,"strong1c",strong,
          "invalidSchemasRejected",3,"fullGameValidated",False)

if __name__=="__main__":
    main()

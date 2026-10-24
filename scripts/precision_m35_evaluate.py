#!/usr/bin/env python3
"""M3.5 bounded native BBA auction throughput baseline, NOT robot strength.

Generates deterministic shuffled 13-card *single hands* from a full deck to
avoid proprietary deal data. Each request has no hidden seats; BBA sees its
own hand only. Failures remain counted, not silently retried or hidden.
"""
from __future__ import annotations
import argparse
import json
import math
import random
import time
from pathlib import Path
import urllib.request
import urllib.error

from precision_m33_sidecar import PINNED_SELECTED_CARD_SHA256, PROFILE_ID

RANKS="AKQJT98765432"
SUITS="SHDC"

def shuffled_hand(seed):
    deck=[(s,r) for s in SUITS for r in RANKS]
    random.Random(seed).shuffle(deck)
    selected=set(deck[:13])
    return ".".join("".join(r for r in RANKS if (s,r) in selected) for s in SUITS)

def call(port,body):
    req=urllib.request.Request(f"http://127.0.0.1:{port}/v1/precision/table-bid",
       data=json.dumps(body,separators=(",",":")).encode(),
       headers={"Content-Type":"application/json"},method="POST")
    try:
        with urllib.request.urlopen(req,timeout=25) as res:
            return res.status,json.load(res)
    except urllib.error.HTTPError as e:
        return e.code,{"error":"http"}
    except (OSError,ValueError):
        return 0,{"error":"transport"}

def percentile(a,p):
    if not a: return None
    a=sorted(a)
    return a[max(0,math.ceil(len(a)*p)-1)]

def process_memory(pid):
    if pid is None:
        return {"available": False}
    try:
        status=Path(f"/proc/{pid}/status").read_text()
        data={}
        for line in status.splitlines():
            if line.startswith(("VmRSS:", "VmHWM:", "VmSize:")):
                key,value=line.split(":",1)
                data[key+"KiB"]=int(value.strip().split()[0])
        return data if data else {"available":False}
    except (OSError, ValueError):
        return {"available":False}

def benchmark(port,cases,pid=None):
    times=[]
    outputs={}
    failures=0
    by_pair={}
    for i in range(cases):
        swap=i%2==1
        ns="BA-SAYC" if swap else PROFILE_ID
        ew=PROFILE_ID if swap else "BA-SAYC"
        seat="E" if swap else "N" # always acting Precision side
        dealer=seat
        row={
            "version":1,"profileId":PROFILE_ID,"revision":1,
            "cardSha256":PINNED_SELECTED_CARD_SHA256,
            "northSouth":ns,"eastWest":ew,
            "seat":seat,"dealer":dealer,"vul":"","ctx":"",
            "hand":shuffled_hand(20261024+i),
        }
        timer=time.monotonic_ns()
        status,res=call(port,row)
        ms=(time.monotonic_ns()-timer)/1000000
        times.append(ms)
        pair="Precision NS vs SAYC EW" if not swap else "SAYC NS vs Precision EW"
        by_pair[pair]=by_pair.get(pair,0)+1
        if status!=200 or res.get("cardSha256")!=PINNED_SELECTED_CARD_SHA256:
            failures+=1
            continue
        bid=res.get("bid")
        outputs[bid]=outputs.get(bid,0)+1
    return {
        "kind":"M35_AUCTION_ONLY_RESEARCH_METRICS",
        "cases":cases,"failedRequests":failures,"successes":cases-failures,
        "nativeBbaAuction":True,"fullBridgeDeals":0,
        "competitiveStrengthValidated":False,
        "expertConventionsValidated":False,
        "target4GbVpsLoadValidated":False,
        "latencyMs":{"p50":round(percentile(times,.5),2),
                     "p95":round(percentile(times,.95),2),
                     "max":round(max(times),2)},
        "bySeatConfiguration":by_pair,
        "bidHistogram":outputs,
        "nativeWorkerMemory":process_memory(pid),
    }

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--port",type=int,default=18088)
    parser.add_argument("--cases",type=int,default=40)
    parser.add_argument("--output",type=Path,required=True)
    parser.add_argument("--pid",type=int)
    args=parser.parse_args()
    if args.cases<1 or args.cases>1000:
        raise SystemExit("number of cases must be 1..1000")
    result=benchmark(args.port,args.cases,args.pid)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2,sort_keys=True)+"\n")
    print("M35_RESEARCH_AUCTION_BASELINE",json.dumps({
        k:v for k,v in result.items() if k!="bidHistogram"
    },sort_keys=True))
    if result["failedRequests"]!=0:
        raise SystemExit("native BBA research requests failed")

if __name__=="__main__":
    main()

#!/usr/bin/env python3
"""A4.5 static deployment safety gate. Does not connect to a public host.

Only non-secret configuration metadata is allowed as input. A passing staging
assessment is NOT evidence that Gateway supports production exposure.
"""
import argparse
import ipaddress
import json
import sys
from pathlib import Path
from urllib.parse import urlsplit

ALLOWED_KEYS = {
    "environment", "public_origin", "tls_termination", "gateway_bind",
    "ben_bind", "raw_decision_enabled", "browser_origins",
    "checkpoint_encrypted", "checkpoint_key_external",
    "anonymous_access", "single_instance", "persistent_rate_limits",
    "external_identity", "distributed_idempotency", "license_approved",
    "capacity_evidence", "rollback_tested",
}
SECRET_MARKERS = ("password", "secret", "token", "private_key", "credential", "api_key")


def origin(value):
    if not isinstance(value, str) or not value:
        return None
    try:
        u = urlsplit(value)
        if u.scheme != "https" or not u.hostname or u.username or u.password:
            return None
        if u.path not in ("", "/") or u.query or u.fragment:
            return None
        if u.port is not None and not (1 <= u.port <= 65535):
            return None
        return f"https://{u.hostname.lower()}" + (f":{u.port}" if u.port else "")
    except ValueError:
        return None


def loopback(value):
    if not isinstance(value, str):
        return False
    try:
        return ipaddress.ip_address(value).is_loopback
    except ValueError:
        return False


def assess(cfg, profile):
    errors = []
    if not isinstance(cfg, dict):
        return ["configuration must be an object"]
    unknown = set(cfg) - ALLOWED_KEYS
    if unknown:
        errors.append("unknown or forbidden configuration keys")
    if any(any(m in k.lower() for m in SECRET_MARKERS) for k in cfg):
        errors.append("secret material keys forbidden")
    if cfg.get("environment") != profile:
        errors.append("environment/profile mismatch")
    public = origin(cfg.get("public_origin"))
    if public is None:
        errors.append("public_origin requires an HTTPS origin without path, credentials or query")
    if cfg.get("tls_termination") is not True:
        errors.append("approved TLS termination not confirmed")
    if not loopback(cfg.get("gateway_bind")):
        errors.append("gateway must remain on literal loopback interface")
    if not loopback(cfg.get("ben_bind")):
        errors.append("BEN must remain on literal loopback interface")
    if cfg.get("raw_decision_enabled") is not False:
        errors.append("legacy caller-hand decision route must be disabled")
    origins = cfg.get("browser_origins")
    if not isinstance(origins, list) or not origins or any(origin(x) is None for x in origins):
        errors.append("browser origins must be explicit HTTPS origins")
    elif len(set(origins)) != len(origins) or public not in origins or "*" in origins:
        errors.append("browser origins must be unique and include the public origin")
    if cfg.get("checkpoint_encrypted") is not True:
        errors.append("encrypted checkpoint store required")
    if cfg.get("checkpoint_key_external") is not True:
        errors.append("checkpoint key must be external; never store key in repo")
    if profile == "production":
        for key, description in (
            ("anonymous_access", "anonymous capability alone is not production authorization"),
            ("single_instance", "single-instance local durability is not HA"),
        ):
            if cfg.get(key) is not False:
                errors.append(description)
        for key in ("persistent_rate_limits", "external_identity", "distributed_idempotency",
                    "license_approved", "capacity_evidence", "rollback_tested"):
            if cfg.get(key) is not True:
                errors.append(f"production gate missing: {key}")
    else:
        # A staging-only static review can be ready to test even though real
        # Gateway hosting, remote HTTPS, and operational acceptance stay open.
        if cfg.get("anonymous_access") is not True:
            errors.append("staging prototype should declare anonymous access explicitly")
        if cfg.get("single_instance") is not True:
            errors.append("staging prototype should declare its single-instance limit")
    return errors


def main(argv=None):
    parser = argparse.ArgumentParser(description="A4.5 static, non-secret configuration check")
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--profile", choices=("staging", "production"), required=True)
    args = parser.parse_args(argv)
    try:
        if args.config.stat().st_size > 16384:
            raise ValueError("configuration exceeds size limit")
        cfg = json.loads(args.config.read_text(encoding="utf-8"))
    except (OSError, ValueError, UnicodeError):
        print("A4.5 FAIL: cannot parse non-secret configuration", file=sys.stderr)
        return 2
    errors = assess(cfg, args.profile)
    if errors:
        print("A4.5 BLOCKED: " + "; ".join(errors), file=sys.stderr)
        return 1
    print(f"A4.5 {args.profile.upper()} STATIC CONFIG PASS — no network or hosted TLS tested")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

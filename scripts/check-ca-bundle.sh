#!/bin/sh
# Fails if a CA bundle still trusts one of the eMudhra-compromised roots (CVE-2026-111943).
#
# Usage: check-ca-bundle.sh <bundle.crt> [more.crt ...]
#
# Why fingerprints and not `grep "emSign ECC Root CA"`: /etc/ssl/certs/ca-certificates.crt
# only holds base64 DER, so subject names never appear in it. The SHA-256 fingerprints
# below are over DER and were published by Alibaba Cloud and AWS.
#
#   emSign ECC Root CA - G3   86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b
#   AAA Certificate Services  d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4
#
# Both roots are needed: the compromised intermediates are cross-signed by Sectigo's
# AAA Certificate Services, so blocking only the emSign root leaves that path open.
set -u

BAD_ROOTS="86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b
d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4"

rc=0

for f in "$@"; do
	if [ ! -f "$f" ]; then
		echo "ERROR: CA bundle not found: $f"
		rc=1
		continue
	fi

	d=$(mktemp -d)
	awk -v d="$d" 'BEGIN { i = 0 } /BEGIN CERT/ { i++ } i > 0 { print > sprintf("%s/c%03d.pem", d, i) }' "$f"
	total=$(ls "$d" | wc -l)
	bad=0

	for c in "$d"/*.pem; do
		fp=$(awk 'BEGIN { p = 0 } /BEGIN CERT/ { p = 1; next } /END CERT/ { p = 0 } p' "$c" \
			| tr -d '\n\r' | base64 -d 2>/dev/null | sha256sum | cut -d' ' -f1)
		for b in $BAD_ROOTS; do
			if [ "$fp" = "$b" ]; then
				echo "FAIL: $f still trusts a compromised eMudhra root ($fp)"
				bad=$((bad + 1))
			fi
		done
	done

	rm -rf "$d"

	if [ "$bad" -eq 0 ]; then
		echo "OK: $f ($total certs) distrusts both compromised eMudhra roots"
	else
		rc=1
	fi
done

exit $rc

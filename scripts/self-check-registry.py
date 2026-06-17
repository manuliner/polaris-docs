#!/usr/bin/env python3
"""Part B of self-check: registry self-consistency. Prints 'DRIFT\\t<msg>' per problem; silent if OK.
Env: SSOT_ROOT, PATTERNS, SSOT_PATTERNS, MANIFEST (paths relative to SSOT_ROOT for the last three)."""
import os, re, json

root = os.environ["SSOT_ROOT"]
def P(p): return os.path.join(root, p)

problems = []

# canonical-skills (from patterns.yaml) must equal the actual template skill dirs.
pat = open(P(os.environ["PATTERNS"])).read()
m = re.search(r"id:\s*canonical-skills.*?values:\s*\[([^\]]*)\]", pat, re.S)
declared = sorted(v.strip() for v in m.group(1).split(",")) if m else []
tpl_dir = P("docs-init/templates")
actual = sorted(d for d in os.listdir(tpl_dir)
                if os.path.isfile(os.path.join(tpl_dir, d, "skill.template.md")))
if declared != actual:
    problems.append("canonical-skills %s != actual template skills %s" % (declared, actual))

# every `ref:` in both registries must point to an existing reference file.
ref_roots = ["docs-init/reference", "docs-init/templates/_shared/reference"]
def ref_exists(name):
    return any(os.path.isfile(P(os.path.join(r, name))) for r in ref_roots)
for reg in (os.environ["PATTERNS"], os.environ["SSOT_PATTERNS"]):
    txt = open(P(reg)).read()
    for ref in set(re.findall(r"^\s*ref:\s*(\S+)", txt, re.M)):
        if not ref_exists(ref):
            problems.append("%s: ref %s not found under %s" % (reg, ref, ref_roots))

# manifest.json must cover every canonical skill's SKILL.md and the _shared families.
man = json.load(open(P(os.environ["MANIFEST"])))
globs = [r["glob"] for r in man.get("rules", [])]
for sk in actual:
    want = sk + "/SKILL.md"
    if want not in globs:
        problems.append("manifest.json has no rule for " + want)
for fam in ("_shared/scripts/**", "_shared/reference/**"):
    if fam not in globs:
        problems.append("manifest.json missing family rule " + fam)

# no dead manifest rule naming a nonexistent skill.
for g in globs:
    mm = re.match(r"(docs-\w+)/SKILL\.md$", g)
    if mm and mm.group(1) not in actual:
        problems.append("manifest.json dead rule for nonexistent skill " + mm.group(1))

for p in problems:
    print("DRIFT\t" + p)

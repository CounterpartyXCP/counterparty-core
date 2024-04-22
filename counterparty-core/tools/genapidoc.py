import os

from counterpartycore import server

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
API_DOC_FILE = os.path.join(CURR_DIR, "../../../Documentation/docs/advanced/api/rest.md")

md = """---
title: REST API V2
---

FORMAT: 1A

# Counterpaty Core API

The Counterparty Core API is the recommended way to query the state of a Counterparty node. The following routes are available.
"""

current_group = None

for path, route in server.routes.ROUTES.items():
    route_group = path.split("/")[1]
    if route_group != current_group:
        current_group = route_group
        md += f"\n## Group {current_group.capitalize()}\n"
    blueprint_path = path.replace("<", "{").replace(">", "}").replace("int:", "")

    title = " ".join([part.capitalize() for part in str(route["function"].__name__).split("_")])
    md += f"\n### {title} [`{blueprint_path}`]\n\n"
    md += route["description"]
    md += "\n\n+ Parameters\n"
    for arg in route["args"]:
        md += f"    + {arg['name']} ({arg['type']}) - {arg.get('description', '')}\n"

with open(API_DOC_FILE, "w") as f:
    f.write(md)

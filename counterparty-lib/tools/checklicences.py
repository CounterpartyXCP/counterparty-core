#!/usr/bin/env python3

import os
import tomllib
import json

# pylint: disable=no-name-in-module
from sh import license_scanner

PACKAGE_NAME = "counterparty-lib"

def scan_licenses():
    cwd = os.path.join(os.getcwd(), PACKAGE_NAME)
    licenses_str = license_scanner(_cwd=cwd).strip()
    licenses = {}
    current_license = None
    for line in licenses_str.split('\n'):
        if line.strip().startswith('=====') or line == "":
            continue
        if line.startswith(' - ') and current_license:
            licenses[current_license].append(line[3:])
            continue
        current_license = line.strip()
        licenses[current_license] = []
    return licenses

def get_allowed():
    pyproject_path = os.path.join(os.getcwd(), PACKAGE_NAME, "pyproject.toml")
    with open(pyproject_path, "rb") as file_pointer:
        data = tomllib.load(file_pointer)
    allowed_licenses = data['tool']['license_scanner']['allowed-licences']
    allowed_packages = data['tool']['license_scanner']['allowed-packages']
    return allowed_licenses, allowed_packages

def generate_sarif(not_allowed_packages):
    results = []
    for license_name in not_allowed_packages:
        for package in not_allowed_packages[license_name]:
            results.append({
                "level": "error",
                "message": {
                    "text": f"Package {package} has license {license_name} which is not allowed"
                },
                "ruleId": "not-allowed-license",
                "locations": [
                    {
                        "physicalLocation": {
                            "artifactLocation": {
                                "uri": f"{PACKAGE_NAME}/pyproject.toml"
                            }
                        }
                    }
                ]
            })
    sarif = {
        "version": "2.1.0",
        "$schema": "http://json.schemastore.org/sarif-2.1.0-rtm.4",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "license-scanner",
                        "notifications": [],
                        "rules": [
                            {
                                "id": "not-allowed-license",
                                "shortDescription": {
                                    "text": "License is not allowed"
                                },
                            }
                        ]
                    }
                },
                "results": results
            }
        ]
    }
    with open("license_scanner.sarif", "w", encoding="UTF-8") as outfile:
        outfile.write(json.dumps(sarif, indent=4))

def check_licenses():
    # Run the license scanner
    used_packages = scan_licenses()
    used_licenses = list(used_packages.keys())
    allowed_licenses, allowed_packages = get_allowed()
    not_allowed_packages = {}
    for license_name in used_licenses:
        if license_name not in allowed_licenses:
            for package in used_packages[license_name]:
                if package not in allowed_packages:
                    if license_name not in not_allowed_packages:
                        not_allowed_packages[license_name] = []
                    not_allowed_packages[license_name].append(package)
    generate_sarif(not_allowed_packages)


if __name__ == '__main__':
    check_licenses()

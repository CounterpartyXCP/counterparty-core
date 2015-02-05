**@ouziel-slama:**

- Quality Assurance
- Update `CHANGELOG.md`
- Update `APP_VERSION` in `counterpartycli/__init__.py`
- Update `counterpartylib` version in `setup.py` (if necessary)
- Merge develop into Master
- Build binaries:
    * In a new VM install Windows dependencies (http://counterparty.io/docs/windows/)
    * `git clone https://github.com/CounterpartyXCP/counterparty-cli.git`
    * `cd counterparty-cli`
    * `python setup.py install`
    * `python setup.py py2exe`
- Send @adamkrellenstein the MD5 of the generated ZIP file

**@adamkrellenstein:**

- Tag and Sign Release (include MD5 hash in message)
- Write [Release Notes](https://github.com/CounterpartyXCP/counterpartyd/releases)
- Upload (signed) package to PyPi
    * `sudo python3 setup.py sdist build`
    * `twine upload -s dist/$NEW_FILES`

**@ouziel-slama:**

- Upload ZIP file in [Github Release](https://github.com/CounterpartyXCP/counterparty-cli/releases)

**@ivanazuber:**:

- Post to [Official Forums](https://forums.counterparty.io/discussion/445/new-version-announcements-counterparty-and-counterpartyd), Skype, [Gitter](https://gitter.im/CounterpartyXCP)
- Post to social media
- SMS and mailing list notifications

# docker-code-standard

## How to run

Update `server/app/tests/static/Webpos/changed_files.txt` with list of files that need to be tested in pos repository.

Ex:
```text
server/app/code/Magestore/Webpos/Controller/Adminhtml/Pos/ForceSignOut.php
server/app/code/Magestore/Webpos/Model/Integration/GiftcardManagement.php
```

Copy `server` folder from the pos repository into this repository's root directory.

Go to this repository's root directory then start docker by below commands:

```bash
docker-compose up -d
```

Run static test:

```bash
docker-compose exec -u www-data magento php bin/magento dev:test:run static -c'--testsuite=PWAPOS'
```



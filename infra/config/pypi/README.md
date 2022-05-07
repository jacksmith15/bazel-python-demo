# PyPi Config


Contains a `.htpasswd` file generated via:

```bash
docker run --rm -it xmartlabs/htpasswd <username> <password>
```

This is mounted and used by PyPi for authentication.

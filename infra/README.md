# Local infrastructure

This directory contains local infrastructure for publishing build outputs.

Bring up the infra:

```bash
docker-compose up -d
```

This will expose an image registry at http://localhost:15000, and a PyPi server at http://localhost:6006.

The credentials for the local PyPi server are `admin` and `password`.

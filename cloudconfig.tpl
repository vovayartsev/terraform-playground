#cloud-config

coreos:
  units:
    - name: app.service
      command: start
      enable: true
      content: |
        [Unit]
        Description=Dockerized App
        After=docker.service

        [Service]
        ExecStart=/usr/bin/docker run --rm --name=app -p 80:8080 dockhero/dockhero-docs:hello
        ExecStop=/usr/bin/docker stop app
        TimeoutStopSec=60s

        [Install]
        WantedBy=multi-user.target

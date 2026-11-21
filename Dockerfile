# Pydio Cells for Railway: the official image, pinned by version and digest,
# plus a small start script that runs the headless first-boot install.
FROM pydio/cells:5.1.1@sha256:91a82e3357a7c76722ff094c2ba2236eccf7819cb6ff9bf4e8aae66627174537

COPY railway-start.sh /opt/pydio/bin/railway-start.sh
RUN chmod 0755 /opt/pydio/bin/railway-start.sh

EXPOSE 8080
ENTRYPOINT ["/sbin/tini", "--", "/opt/pydio/bin/railway-start.sh"]
CMD ["cells", "start"]

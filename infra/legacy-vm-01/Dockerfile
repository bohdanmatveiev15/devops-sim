FROM rockylinux:8

RUN dnf install -y openssh-server cronie python3 python3-psycopg2 sudo passwd hostname procps-ng less vim-minimal \
    && dnf clean all \
    && sed -i 's/^session\(\s*\)required\(\s*\)pam_loginuid.so/session\1optional\2pam_loginuid.so/' /etc/pam.d/sshd /etc/pam.d/crond \
    && useradd -m -u 2001 -s /bin/bash bohdan \
    && usermod -p '*' bohdan \
    && useradd -m -u 2002 -s /bin/bash ops-admin \
    && mkdir -p /opt/reports/bin /opt/reports/etc /opt/reports/out /var/log/legacy-reports

COPY generate_report.py /opt/reports/bin/generate_report.py
COPY settings.ini.tmpl /usr/local/share/reports/settings.ini.tmpl
COPY legacy-reports.cron /etc/cron.d/legacy-reports
COPY ops-admin.sudoers /etc/sudoers.d/ops-admin
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod 755 /opt/reports/bin/generate_report.py \
    && chmod 644 /etc/cron.d/legacy-reports \
    && chmod 440 /etc/sudoers.d/ops-admin

EXPOSE 22
CMD ["/usr/local/bin/entrypoint.sh"]

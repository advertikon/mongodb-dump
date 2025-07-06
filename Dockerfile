FROM ubuntu:24.10

RUN apt update -qq && apt install -qq -y wget unzip && apt clean

RUN wget -q https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2404-x86_64-100.12.1.deb
RUN apt install -qq -y ./mongodb-database-tools-ubuntu2404-x86_64-100.12.1.deb
RUN rm mongodb-database-tools-ubuntu2404-x86_64-100.12.1.deb

RUN wget -q https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -O awscliv2.zip
RUN unzip -q awscliv2.zip
RUN ./aws/install
RUN rm -rf awscliv2.zip aws

RUN echo "SLACK_MESSAGES_WEBHOOK=${SLACK_MESSAGES_WEBHOOK}" > ".env"

COPY scripts/backup.sh scripts/restore.sh ./

CMD ["./backup.sh"]

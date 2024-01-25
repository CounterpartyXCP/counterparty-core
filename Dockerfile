FROM ubuntu:22.04

RUN apt-get update
RUN apt install -y python3-pip wget git

ENV HOME /root
WORKDIR /root

RUN mkdir -p ~/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
RUN /root/miniconda3/bin/conda create -n xcp python=3.6
RUN /root/miniconda3/bin/conda init bash
ENV PATH /root/miniconda3/envs/xcp/bin:$PATH

RUN git clone https://github.com/CounterpartyXCP/counterparty-lib.git
RUN cd /root/counterparty-lib && \
    pip3 install --upgrade -r requirements.txt && \
    python3 setup.py install

RUN git clone https://github.com/CounterpartyXCP/counterparty-cli.git
RUN cd /root/counterparty-cli && \
    pip3 install --upgrade -r requirements.txt && \
    python3 setup.py install

COPY docker/server.conf /root/.config/counterparty/server.conf

EXPOSE 4000

ENTRYPOINT counterparty-server start

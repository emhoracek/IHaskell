FROM ubuntu:14.04

# Install all necessary Ubuntu packages
RUN apt-get update && \
    apt-get install -y python3-dev python3-setuptools python3-pip libncurses5-dev libmagic-dev libtinfo-dev libzmq3-dev libcairo2-dev libpango1.0-dev libblas-dev liblapack-dev gcc g++ && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 575159689BEFB442 && \
    echo 'deb http://download.fpcomplete.com/ubuntu trusty main' > /etc/apt/sources.list.d/fpco.list && \
    apt-get update && \
    apt-get install -y stack && \
    pip3 install -U jupyter jupyterhub && \
    apt-get clean

# Create jovyan user with UID=1000 and in the 'users' group
ENV NB_UID 1000
ENV NB_USER jovyan
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

USER $NB_USER

# Setup jovyan home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/ihaskell
WORKDIR /home/$NB_USER/ihaskell

# Set up stack
COPY deps /home/$NB_USER/ihaskell
COPY start-singleuser.sh /home/$NB_USER/.local/bin/start-singleuser.sh
RUN stack setup --allow-different-user

# Install dependencies for IHaskell

USER root
RUN chown -R $NB_USER:users /home/$NB_USER/
USER $NB_USER

# Install IHaskell itself.
RUN stack build --allow-different-user && stack install --allow-different-user

# Run the notebook
ENV PATH /home/$NB_USER/ihaskell/.stack-work/install/x86_64-linux/nightly-2015-08-15/7.10.2/bin:/home/$NB_USER/.stack/snapshots/x86_64-linux/nightly-2015-08-15/7.10.2/bin:/home/$NB_USER/.stack/programs/x86_64-linux/ghc-7.10.2/bin:/home/$NB_USER/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/bin/

RUN ihaskell install

USER root
RUN chown -R $NB_USER:users /home/$NB_USER/work
USER $NB_USER

CMD ["start-singleuser.sh"]

EXPOSE 8888

USER $NB_USER
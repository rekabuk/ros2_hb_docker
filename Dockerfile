#####################################################################
##                                                                 ##
##                          ROBOT VERSION                          ##
##                                                                 ## 
#####################################################################


# Build command
# docker image build -t ros_hbbot_image .

# Run command
# docker run -it --user andrew --network=host --ipc=host -v /home/andrew/wsdev:/home/andrew/wsdev -v /tmp.X11-unix:/tmp/.X11-unix:rw --env=DISPLAY ros_image

# Base image
FROM ros:humble

# Install nano
RUN apt-get update \
    && apt-get install -y nano \
    && rm -rf /var/lib/apt/lists/*

# Copy permenant files
#COPY

#Reference external files

#Create user
# Create a non-root user
ARG USERNAME=andrew
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config

# Instructions after here are run as "ros", previously it would be "root"
#USER ros

# Set up sudo
RUN apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && rm -rf /var/lib/apt/lists/*

# Programs for device testing
RUN apt-get update \
  && apt-get install -y \
     evtest \
     jstest-gtk \
     python3-serial \
  && rm -rf /var/lib/apt/lists/*

# Programs for i2c on the Pi
RUN apt-get update \
  && apt-get install -y \
     i2c-tools \
     libi2c-dev \
  && rm -rf /var/lib/apt/lists/*

# PiGpio
RUN cd /home/${USERNAME} \
    && git clone https://github.com/joan2937/pigpio.git \
    && cd pigpio \
    && make \
    && sudo make install \
    && cd .. \
    && rm -rf /home/${USERNAME}/pigpio 

RUN apt-get update \
    && apt-get -y install cron \
    && rm -rf /var/lib/apt/lists/*
    
COPY cjob /etc/cron.d/cjob
RUN chmod 0644 /etc/cron.d/cjob
CMD cron && tail -f /var/log/cron.log    

# Copy the entrypoint and bashrc scripts so we have 
# our container's environment set up correctly
COPY entrypoint.sh /entrypoint.sh
COPY bashrc /home/${USERNAME}/.bashrc

# Set up entrypoint and default command
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD ["bash"]

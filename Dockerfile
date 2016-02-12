FROM ubuntu
 
# quiets down mesg to console about TERM not being set
ENV TERM linux
USER root
 
RUN apt-get update \
    && apt-get install -qqy \
    openssh-client \
    wget \
    git \
    gawk \
    libusb-1.0-0-dev \
    freeglut3-dev \
    openjdk-7-jdk \
    doxygen \
    graphviz \
    software-properties-common \
    cmake build-essential \
    xterm

# Install additionnal useful packages
RUN apt-get update && apt-get install -y -qq \
    bash-completion \
    module-init-tools \
    nautilus \
    tmux \
    vim 

# install Nvidia
# RUN apt-get install -y -qq binutils mesa-utils
# RUN add-apt-repository ppa:xorg-edgers/ppa && apt-get update
# RUN apt-get install -y -qq nvidia-352 nvidia-settings
# RUN ldconfig
 
# install OpenNI 
ADD resources/OpenNI-Bin-Dev-Linux-x64-v1.5.7.10.tar.bz2 /tmp
RUN cd /tmp/OpenNI-Bin-Dev-Linux-x64-v1.5.7.10 \
    && ./install.sh
RUN rm -rf /tmp/OpenNI-Bin-Dev-Linux-x64-v1.5.7.10
 
# getting ROS packages because they contain all the openni,opencv/pcl goodness needed
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu trusty main" > /etc/apt/sources.list.d/ros-latest.list'
RUN wget http://packages.ros.org/ros.key -O - | apt-key add -
RUN apt-get update \
    && apt-get install -qqy \
    ros-indigo-perception-pcl \
    ros-indigo-vision-opencv
 
RUN add-apt-repository --yes ppa:xqms/opencv-nonfree
RUN apt-get update \
    && apt-get install -qqy \
    libopencv-nonfree-dev
 
# if UsbInterface is commented out, remove the comment char and flag(DJL) as changed
RUN sed -i '/;UsbInterface=2/c\UsbInterface=2;DJL' /etc/openni/GlobalDefaults.ini
 
# install NiTE middleware
ADD resources/NITE-Bin-Linux-x64-v1.5.2.23.tar.bz2 /tmp
RUN cd /tmp/NITE-Bin-Dev-Linux-x64-v1.5.2.23 \
    && ./install.sh
RUN rm -rf /tmp/NITE-Bin-Dev-Linux-x64-v1.5.2.23
 
# install Sensor Driver 
ADD resources/Sensor-Bin-Linux-x64-v5.1.6.6.tar.bz2 /tmp
RUN cd /tmp/Sensor-Bin-Linux-x64-v5.1.6.6 \
    && ./install.sh
RUN rm -rf /tmp/Sensor-Bin-Linux-x64-v5.1.6.6 
 
# add a user and add the user to the sudoers list
RUN useradd -ms /bin/bash docker
RUN sed -i '/root\tALL/i\docker\tALL=(ALL:ALL) ALL' /etc/sudoers \
    && echo 'docker:docker' | chpasswd
USER docker
 
# get rgbdemo
RUN cd /home/docker \
    && git clone --recursive https://github.com/rgbdemo/rgbdemo.git
RUN cd /home/docker/rgbdemo \
# fix linux_configure.sh to use OpenNI not OpenNI2
    && sed -i '/\$\*/i\    -DNESTK_USE_OPENNI2=0 \\' linux_configure.sh \
#edit scan_markers/ModelAcquisitionWindow.cpp, comment out line 57,58,59,60,61
    && cd scan-markers \
    && gawk '/if \(!m_controller/, c==4 {$0 = "//" $0; c++} { print }' ModelAcquisitionWindow.cpp > /tmp/tmpfile \
    && cp /tmp/tmpfile ModelAcquisitionWindow.cpp
RUN  cd /home/docker/rgbdemo \
    && ./linux_configure.sh \
    && cd build \
    && make

ENV USER docker 
USER docker

# Change entrypoint to run provided script 
COPY entrypoint.sh /entrypoint.sh
# RUN sudo chmod +x /entrypoint.sh ; sudo chown docker /entrypoint.sh ; 

ENV DISPLAY :0
#because some gui widgets were not loading
ENV QT_X11_NO_MITSHM 1
 
#ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

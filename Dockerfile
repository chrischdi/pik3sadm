FROM scratch

ARG rootfs_tar
ARG qemu_binary

# add rootfs
ADD $rootfs_tar /
# enable qemu emulation
COPY $qemu_binary /usr/bin/

# do stuff
RUN pacman-key --init && pacman-key --populate archlinuxarm
RUN pacman -Syyuu --noconfirm

# install stuff
RUN pacman --noconfirm -S \
    htop \
    sudo \
    vim

# remove some stuff
RUN pacman --noconfirm -R \
  lvm2 \
  man-db \
  man-pages \
  mdadm \
  nano \
  reiserfsprogs \
  wireless_tools \
  wpa_supplicant

RUN pacman -S --needed --noconfirm f2fs-tools xfsprogs

RUN pacman -S --needed --noconfirm \
  wireguard-tools \
  wireguard-dkms

# remove user alarm
RUN userdel alarm \
  && rm -rf /home/alarm

RUN groupadd -g 1000 kube \
  && useradd -m -g kube -u 1000 kube \
  && usermod -aG wheel kube \
  && echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

ADD image/pik3s-init.service /etc/systemd/system/
RUN systemctl enable pik3s-init.service

# cleanup
RUN rm -rf /temp \
  && pacman -Scc --noconfirm \
  && rm -rf /etc/machine-id


# RUN rm -rf \
#   /usr/bin/$(basename $qemu_binary)

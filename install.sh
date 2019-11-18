#!/bin/bash

# Instructions from http://www.clifford.at/icestorm/

# TODO: Support non-root installations
# Base software installations
echo "Installing base software..."
sudo apt-get install -y build-essential clang bison flex libreadline-dev \
                     gawk tcl-dev libffi-dev git mercurial graphviz   \
                     xdot pkg-config python python3 libftdi-dev \
                     qt5-default python3-dev libboost-all-dev cmake

echo "Installing icestorm..."
pushd icestorm > /dev/null
make -j$(nproc)
sudo make install
popd > /dev/null

echo "Installing arachne-pnr..."
pushd arachne-pnr > /dev/null
make -j$(nproc)
sudo make install
popd > /dev/null

echo "Installing nextpnr..."
pushd nextpnr
cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
make -j $(nproc)
sudo make install
popd > /dev/null

echo "Installing yosys..."
pushd yosys
make -j$(nproc)
sudo make install
popd > /dev/null

echo "Installing USB programmer..."
echo -e "ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6010\", MODE=\"0660\", GROUP=\"plugdev\", TAG+=\"uaccess\"" | sudo tee /etc/udev/rules.d/53-lattice-ftdi.rules

echo "Installation done!"


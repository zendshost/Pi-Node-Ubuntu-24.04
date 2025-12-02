# Install dependencies
sudo apt update
sudo apt install -y ca-certificates curl gnupg
------------------------
# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
------------------------
# Add Docker’s apt repository
echo \
  "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
------------------------
# Install docker-ce
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
------------------------
sudo systemctl status docker
------------------------
sudo install -m 0755 -d /etc/apt/keyrings
------------------------
curl -fsSL https://apt.minepi.com/repository.gpg.key \
 | sudo gpg --dearmor -o /etc/apt/keyrings/pinetwork-archive-keyring.gpg
------------------------
sudo chmod a+r /etc/apt/keyrings/pinetwork-archive-keyring.gpg
------------------------
sudo rm -f /etc/apt/sources.list.d/pinetwork.list
------------------------
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/pinetwork-archive-keyring.gpg] https://apt.minepi.com stable main" \
 | sudo tee /etc/apt/sources.list.d/pinetwork.list > /dev/null
------------------------
sudo apt update
------------------------
sudo apt install pi-node
------------------------
ls -l /etc/apt/sources.list.d/
cat /etc/apt/sources.list.d/pinetwork.list
apt update
------------------------
pi-node --version
------------------------
pi-node initialize
------------------------
sudo systemctl start docker
------------------------
sudo systemctl enable docker
------------------------
 cd /root/pi-node
------------------------
 pi-node status
------------------------

# Load Balancer dengan Nginx, Docker, Kubernetes, dan Minikube

Proyek ini adalah implementasi Load Balancer menggunakan Nginx, Docker, Kubernetes, dan Minikube. Load Balancer ini mendistribusikan trafik dari pengguna ke beberapa pod yang menjalankan aplikasi di dalam cluster Kubernetes.

## Installation

### Install Dependencies

Pastikan untuk memperbarui sistem dan menginstal dependensi yang diperlukan dengan perintah berikut:

```bash
sudo apt update && sudo apt upgrade -y
```
### Install Docker
```bash
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker
```
### Set Docker Without Sudo
Tambahkan user ke grup Docker untuk menjalankan Docker tanpa sudo:
```bash
sudo usermod -aG docker $USER
newgrp docker
```
### Install Kubernetes dan Minikube
Setelah itu, ikuti langkah-langkah berikut untuk menambahkan repository Kubernetes dan menginstal Minikube:
```bash
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
sudo apt install -y kubectl kubeadm kubelet
sudo apt-mark hold kubectl kubeadm kubelet
```
### Install Minikube
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --driver=docker #Jalankan di luar user root
```
### Install Nginx
```bash
sudo apt install nginx -y
sudo apt install apt-transport-https curl -y
```
### Usage
Folder Structure
Setelah menginstal semua dependensi, buat struktur folder untuk proyek:
```bash
mkdir loadbalancer && cd loadbalancer
mkdir web && mkdir k8s
```
### Folder Structure
```bash
/loadbalancer
│
├── /k8s           # Konfigurasi Kubernetes
│   ├── loadbalancer-deployment.yaml  # Deployment untuk aplikasi
│   ├── loadbalancer-service.yaml     # Service yang expose aplikasi
│
├── /web                  # Website yang dijalankan di Nginx
│   ├── index.html        # Halaman utama website
│   ├── [file lainnya]    # File website lainnya (CSS, JS, dll)
│
├──├── Dockerfile        # Dockerfile untuk container aplikas  
```
### Build Docker Image
Tarik image nginx:alpine dan buat Dockerfile untuk load balancer:
```bash
docker pull nginx:alpine
nano Dockerfile
```
Isi Dockerfile dengan script berikut:
```bash
FROM nginx:alpine
COPY web /usr/share/nginx/html
CMD ["sh", "-c", "echo $(hostname) > /usr/share/nginx/html/hostname && nginx -g 'daemon off;'"]
```
Setelah itu, bangun image Docker dengan perintah:
```bash
docker build -t lbdayus/nama-image-baru .
```
### Push Docker Image to DockerHub
Login ke akun DockerHub dan push image yang telah dibuat:
```bash
docker login -u usernamekalian
docker tag lbdayus:latest usernamekalian/lbdayus:latest
docker push usernamekalian/lbdayus:latest
```
### Kubernetes Configuration
### 
File Deployment dan Service
Buat file konfigurasi untuk deployment dan service.

### Deployment (loadbalancer-deployment.yaml):
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loadbalancer
spec:
  replicas: 5
  selector:
    matchLabels:
      app: loadbalancer
  template:
    metadata:
      labels:
        app: loadbalancer
    spec:
      containers:
      - name: ammunitue
        image: spiuwirkid/lbdayus:latest  # Sesuaikan dengan image yang dibuat
        ports:
        - containerPort: 80
        env:
        - name: POD_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
```
### Service (loadbalancer-service.yaml):
```bash
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: loadbalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 31956
  type: NodePort
  sessionAffinity: None
```
### Apply Konfigurasi Kubernetes
Setelah membuat file konfigurasi deployment dan service, terapkan konfigurasi tersebut:
```bash
kubectl apply -f loadbalancer-deployment.yaml
kubectl apply -f loadbalancer-service.yaml
```
### Verifikasi Pods dan IP
Cek apakah pods sudah berjalan dengan baik:
```bash
kubectl get pods
```
### Untuk mendapatkan IP Minikube dan port Kubernetes Service:
```bash
kubectl get svc
minikube ip
```
### Contoh IP Minikube dan Port Kubernetes Service:
kubectl get svc:
```bash
ubuntu@ip-10-0-19-160:~$ kubectl get svc
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP        100m
my-app-service   NodePort    10.103.95.229   <none>        80:31956/TCP   95m
```
minikube ip:
```bash
ubuntu@ip-10-0-19-160:~$ minikube ip
192.168.49.2
ubuntu@ip-10-0-19-160:~$
```
### IP dan Port Service Kubernetes:
```bash
192.168.49.2:31956
```
### Nginx Proxy Configuration
Mengatur Proxy di Nginx
Konfigurasi proxy di Nginx untuk load balancing:
```bash
nano /etc/nginx/conf.d/loadbalancer.conf
```
Masukkan konfigurasi berikut:
```bash
upstream web_servers {
    server 192.168.49.2:31956;  # Minikube IP dan port
}

server {
    listen 80;

    location / {
        proxy_pass http://web_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /hostname {
        proxy_pass http://web_servers/hostname;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
### Testing
Test apakah load balancer bekerja dengan menjalankan perintah curl:
```bash
curl 192.168.49.2:31956
```
Jika berhasil, outputnya akan memunculkan website yang dijalankan oleh Kubernetes.

### Remove Default Nginx Configuration
Terakhir, hapus konfigurasi default Nginx:
```bash
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
```
### Conclusion
The load balancer is now up and running! Nginx successfully proxies traffic to Kubernetes pods and distributes it evenly. Everything is orchestrated by Kubernetes and packaged in Docker containers.

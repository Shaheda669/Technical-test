#!/bin/bash

# Create directory structure
mkdir -p ansible_playbook
cd ansible_playbook
mkdir tasks files

# Create the main playbook (main.yml)
cat > main.yml << EOF
---
- name: Provisioning Playbook
  hosts: localhost
  become: yes
  gather_facts: no

  tasks:
    - name: Change system open file limit for root
      sysctl:
        name: fs.file-max
        value: 65536
EOF

# Create the create_user_accounts task file (create_user_accounts.yml)
cat > tasks/create_user_accounts.yml << EOF
---
- name: Create user accounts and copy info files
  hosts: localhost
  tasks:
    - name: Create user accounts
      user:
        name: "{{ item.key }}"
        comment: "{{ item.value.name }}"
        groups: "{{ item.value.groups }}"
        shell: /bin/bash
        createhome: yes
        generate_ssh_key: yes
      with_dict: "{{ user_accounts }}"
      tags: user

    - name: Copy info files
      copy:
        content: "name: {{ item.value.name }}\nposition: {{ item.value.position }}\noffice: {{ item.value.office }}"
        dest: "/home/{{ item.key }}/info"
      with_dict: "{{ user_accounts }}"
      tags: user
EOF

# Create the install_docker task file (install_docker.yml)
cat > tasks/install_docker.yml << EOF
---
- name: Install Docker and run a container
  hosts: localhost
  tasks:
    - name: Install Docker
      apt:
        name: docker.io
        state: present
      tags: docker

    - name: Run Docker container
      docker_container:
        name: happy_roentgen
        image: public.ecr.aws/q0x2y8f9/nginx-demo
        ports:
          - "55000:55000"
      tags: docker
EOF

# Create the download_and_copy_file task file (download_and_copy_file.yml)
cat > tasks/download_and_copy_file.yml << EOF
---
- name: Download and copy prrtprrt.txt file
  hosts: localhost
  tasks:
    - name: Download prrtprrt.txt file
      get_url:
        url: "https://gist.githubusercontent.com/slgevens/aa9a2fc52cb5fef8b41c1b11a8b7d3e3/raw/dc1e3e288967bd4818277e4688d1daf615225337/prrtprrt.txt"
        dest: "files/prrtprrt.txt"
      tags: file

    - name: Copy prrtprrt.txt file to user directories
      copy:
        src: "files/prrtprrt.txt"
        dest: "/home/{{ item.key }}/prrtprrt.txt"
      with_dict: "{{ user_accounts }}"
      tags: file
EOF

# Create an empty encrypt_sensitive_data task file (encrypt_sensitive_data.yml)
touch tasks/encrypt_sensitive_data.yml

# Create the install_nginx task file (install_nginx.yml)
cat > tasks/install_nginx.yml << EOF
---
- name: Install Nginx and configure port forwarding
  hosts: localhost
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
      tags: nginx

    - name: Configure Nginx for port forwarding
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      tags: nginx

    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
      tags: nginx
EOF

# Create the Nginx configuration template (nginx.conf.j2)
cat > tasks/nginx.conf.j2 << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name localhost;
        location / {
            proxy_pass http://happy_roentgen:55000;
        }
    }
}
EOF

echo "Directory structure and files created successfully."

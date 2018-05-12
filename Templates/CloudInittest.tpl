{                        
    "commandToExecute": "yum install -y epel-release > /dev/null && yum install -y nginx > /dev/null && systemctl start nginx && echo 'bootscript done' > /tmp/result.txt"
}

<?php
$servers = '192.168.1.1 192.168.1.2 192.168.1.3 192.168.1.4';
$pwds = 'www123 www456 www678';
$shell_script = "/auto-install/init.sh";
$cmdStr = "{$shell_script} {$servers} {$pwds}";
exec("{$cmdStr} >> auto-install/shell.log 2>&1 ", $results, $status );
if($status !== 0){
     exit("脚本执行错误");
}
echo "正在执行中....";


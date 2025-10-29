flutter build web --wasm --base-href /fftgames/

# Ensure the dev drive (F: at work, D: at home) is mounted
Invoke-Expression "wsl -- sudo mount -t drvfs $($pwd.drive.name): /mnt/$($pwd.drive.name.ToLower())"

wsl -- rsync -avz --stats -p --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r --chown=josh2112:www-data build/web/* josh2112@joshuafoster.info:/var/www/public/fftgames
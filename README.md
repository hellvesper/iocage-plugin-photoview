# iocage-plugin-photoview

Photoview gallery plugin for TrueNAS

Photoview is a simple and user-friendly photo gallery that's made for photographers and aims to provide an easy and fast way to navigate directories, with thousands of high-resolution photos.

Site: https://photoview.github.io
Demo: https://photos.qpqp.dk/
Docs: https://photoview.github.io/en/docs/
Source: https://github.com/photoview/photoview

## About plugin

This plugin uses full install with optional features of Photoview, it additionaly installed `ffmpeg` to convert unsupported videos, and `darktable` for RAW photos formats, it also installed ExifTool to fetch metadata from media files.

The installation also configure mDNS service, so you can acces service in your local network by local domains names in `.local` zone. Default domain name will be http://photoview.local .

If you have more than 1 instanse installed or jail with same name your domain name will be like `photociew-x.local`, where x - is number 1-n. To find out which hostname had installed service go to TrueNAS admin panel → Jails.

### Add existing share to Gallery.

After pluging installed, you should add mount point to it.
* Go to TrueNAS → Jails
* Locate your plugin jail, it will be names `photovew`. Press on arrow `>` on the row to open menu
* Press STOP  button to stop jail if it running, then press  MOUNT POINTS, you will redirect to new window
* In the Jails / Mount Points press on blue ACTIONS button and chose ADD
* From the upper `Source` section choose  your directory with photos/video that you want to add to the Gallery. And from the bottom `Destination` choose directory where `Source` whill be mounted. Usually it `/mnt` or `/media`, then press SUBMIT button
* Navigate to `Jails` or `Plugins`,  check plugin jail and press START

That it. Now open photoview in your browser and if you didn't create an account yet, you will be promted for new user. Enter yout login, password, and a path to directory (`Destination`), if you choosed `/mnt` or `/media` - enter `/mnt` or `/media`

### Install plugin from this repository instead of Community Hub

You can install this plugin manually directly from this repository.
To do this navigate to TrueNAS → Shell, and enter command: `iocage fetch -P photoview -g https://github.com/hellvesper/iocage-plugin-index`
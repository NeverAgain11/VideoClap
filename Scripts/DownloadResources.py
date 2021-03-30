import requests
import os
import matplotlib.pyplot as plt

def download_file(filename, url):
    save_path = f"../Mat/{filename}"
    if os.path.lexists(save_path):
        return
    with open(save_path, "wb") as fw:
        with requests.get(url, stream=True) as r:
            print('-' * 30)
            print("file name:", filename)
            print("file type:", r.headers["Content-Type"])
            filesize = r.headers["Content-Length"]
            print("file size:", filesize, "bytes")
            print("download url:", url)
            print("save path:", save_path)
            print('-' * 30)
            print("start download")

            chunk_size = 128
            times = int(filesize) // chunk_size
            show = 1 / times
            start = 1
            for chunk in r.iter_content(chunk_size):
                fw.write(chunk)
                if start <= times:
                    print(f"progress: {show:.2%}")
                    start += 1
                    show += 1 / times
                else:
                    print("progress: 100%\r")
            print("\nfinish")

def create_image():
    fig = plt.figure(1, dpi=100)
    plt.subplot(111)
    plt.savefig("../Mat/Anniversary1.png", transparent=True, format="png")


if __name__ == '__main__':
    if os.path.lexists("../Mat") == False:
        os.mkdir("../Mat")

    download_objecs = {
        "video1.mp4": "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
        "video0.mp4": "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
        "test1.jpg": "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg",
        "test3.jpg": "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/SubaruOutbackOnStreetAndDirt.jpg",
        "test4.jpg": "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg",
        "d6943138af1.gif": "https://upload.wikimedia.org/wikipedia/commons/a/a0/Cartoon_steamer_duck_walking_animation.gif",
        "Watermelon.json": "https://raw.githubusercontent.com/airbnb/lottie-ios/master/Example/lottie-swift/TestAnimations/Watermelon.json",
        "AMS__Big_Explosion.mov": "https://content.videvo.net/videvo_files/video/free/2015-01/originalContent/AMS__Big_Explosion.mov",
        "A0482_F1507_P2_Green_Comp_1.mov": "https://content.videvo.net/videvo_files/video/free/2015-07/originalContent/A0482_F1507_P2_Green_Comp_1.mov",
        "moving_flares.mov": "https://content.videvo.net/videvo_files/video/free/2016-02/originalContent/moving_flares.mov",
        "Anniversary1.png": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTG-QT6ve8WPX-FBYJibdnSrJJSBzbPOXXS8w&usqp=CAU",
        "MotionCorpse-Jrcanest.json": "https://raw.githubusercontent.com/airbnb/lottie-ios/master/Example/lottie-swift/TestAnimations/MotionCorpse-Jrcanest.json",
        "02.Ellis - Clear My Head (Radio Edit) [NCS].mp3": "https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3",
        "lut_filter_27.jpg": "https://raw.githubusercontent.com/rakyll/obs-luts/master/luts/mono.png",
        }

    for filename, url in download_objecs.items():
        download_file(filename, url)

    create_image()
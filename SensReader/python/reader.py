import argparse
import os, sys

from SensorData import SensorData

# params
parser = argparse.ArgumentParser()
# data paths
parser.add_argument(
    "--filename",
    required=True,
    help="path to sens file to read",
)
parser.add_argument(
    "--output_path",
    help="path to output folder",
)
parser.add_argument(
    "--export_depth_images",
    dest="export_depth_images",
    action="store_true",
)
parser.add_argument(
    "--export_color_images",
    dest="export_color_images",
    action="store_true",
)
parser.add_argument(
    "--export_poses",
    dest="export_poses",
    action="store_true",
)
parser.add_argument(
    "--export_intrinsics",
    dest="export_intrinsics",
    action="store_true",
)
parser.add_argument(
    "--export_timestamps",
    dest="export_timestamps",
    action="store_true",
)
parser.add_argument(
    "--image_size",
    dest="image_size",
    type=int,
    nargs=2,
    help="Size of the exported color images.",
)
parser.set_defaults(
    output_path=None,
    export_depth_images=False,
    export_color_images=False,
    export_poses=False,
    export_intrinsics=False,
    export_timestamps=False,
    image_size=None,
)

opt = parser.parse_args()
print(opt)


def main():
    # If not specified use the same directory as the .sens file
    if opt.output_path is None:
        opt.output_path = os.path.dirname(opt.filename)
    os.makedirs(opt.output_path, exist_ok=True)
    # load the data
    sys.stdout.write("loading %s..." % opt.filename)
    sd = SensorData(opt.filename)
    sys.stdout.write("loaded!\n")
    if opt.export_depth_images:
        sd.export_depth_images(os.path.join(opt.output_path, "depth"))
    if opt.export_color_images:
        sd.export_color_images(
            os.path.join(opt.output_path, "color"),
            image_size=opt.image_size,
        )
    if opt.export_poses:
        sd.export_poses(os.path.join(opt.output_path, "pose"))
    if opt.export_intrinsics:
        sd.export_intrinsics(os.path.join(opt.output_path, "intrinsic"), opt.image_size)
    if opt.export_timestamps:
        sd.export_imu_timestamps(os.path.join(opt.output_path, "timestamps.csv"))


if __name__ == "__main__":
    main()

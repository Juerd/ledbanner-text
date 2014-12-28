#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(sleep);
use Image::Magick;

undef $/;
$| = 1;

sub read_image {
    my ($color, $text) = @_;

    # save image to string
    my $rgb_string = "";
    open IMAGE, '>', \$rgb_string;

    # create new image structure
    my $image = Image::Magick->new;
    #$image->Set(debug => 'All');

    # create empty image & query width
    $image->ReadImage('canvas:black');
    my ($x_ppem, $y_ppem, $ascender, $descender, $width, $height, $max_advance) = $image->QueryFontMetrics(
        gravity => 'center',
        font => 'nokiafc22.ttf',
        background => 'black',
        pointsize => 8,
        fill => $color,
        kerning => 0,
        'interword-spacing' => 5,
        text => $text);

    # create new empty image with width
    $image->Set(size => $width . 'x8', depth => 8);
    $image->ReadImage('canvas:black');

    # write text
    $image->Annotate(
        gravity => 'center',
        font => 'nokiafc22.ttf',
        background => 'black',
        pointsize => 8,
        fill => $color,
        kerning => 0,
        'interword-spacing' => 5,
        text => $text);

    # write image
    $image->Write(file=>\*IMAGE, filename=>'RGB:-');
    close IMAGE;

    return $rgb_string;
}

my $color = shift @ARGV;
my $text = shift @ARGV;
my $image = read_image($color, $text);
my $width = length($image) / (8 * 3);
my $next_image;

for my $index (0..0) {
    for my $x (($index == 0 ? 1 : 80) .. 80 + $width) {
        my $out = "\0" x 1920;
        for my $y (0..7) {
            my $src_left = $y * $width;
            if ($x > 80) {
                $src_left += $x - 80;
            }
            my $dst_left = $y * 80;
            my $target   = $dst_left + (80 - ($x > 80 ? 80 : $x));
            my $length   = ($x > 80 ? 80 : $x);
            if ($x > $width) {
                $length += $width - $x;
            }
            
            substr $out, $target * 3, $length * 3, #"\x40" x $length;
                substr $image, $src_left * 3, $length * 3;
        }
        print $out;
#        sleep length($text) < 40 ? .015 : .010;
        sleep 0.0253;
    }
    # $image = $next_image;

}

close STDOUT;

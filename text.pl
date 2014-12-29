#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(sleep);
use Image::Magick;
use File::Slurp;

undef $/;
$| = 1;

sub read_image {
    my ($color, $text) = @_;

    # create new image structure
    my $image = Image::Magick->new;
    #$image->Set(debug => 'All');
    $image->Set(size => '5000x8', depth => 8);

    my @pieces = split(/&:&/, $text);
    my @width;
    my @colors;
    my $allwidth = 0;
    my $i = 0;
    foreach my $piece (@pieces) {
       $colors[$i] = $color;
       if ($piece =~ s/(#[0-9A-Fa-f]{6})//) {
         $colors[$i] = $1;
       }
       print STDERR "color piece ".$i." = ".$colors[$i].": ".$piece."\n";

       # create empty image & query width
       $image->ReadImage('canvas:black');
       my ($x_ppem, $y_ppem, $ascender, $descender, $textwidth, $height, $max_advance) = $image->QueryFontMetrics(
         gravity => 'center',
         font => 'nokiafc22.ttf',
         pointsize => 8,
         fill => $color,
         kerning => 0,
         'interword-spacing' => 5,
         text => $piece);
       $width[$i++] = $textwidth;
       $allwidth += $textwidth+2;
    }
    $allwidth += 50;

    # create new empty image with width
    $image = Image::Magick->new;
    $image->Set(size => $allwidth . 'x8', depth => 8);
    $image->ReadImage('canvas:black');

    my $x = 0;
    $i = 0;

    foreach my $piece (@pieces) {
       # write text
       $image->Annotate(
         x => $x,
         gravity => 'center',
         font => 'nokiafc22.ttf',
         pointsize => 8,
         fill => $colors[$i],
         kerning => 0,
         'interword-spacing' => 5,
         text => $piece);
       $x += $width[$i++]+2;
    }

    # write image
    $image->Write(filename=>'PNG:/tmp/text.pl.bork.png');
    $image->Write(filename=>'RGB:/tmp/text.pl.bork.rgb');

    return read_file('/tmp/text.pl.bork.rgb');
}

my $color = shift @ARGV;
my $text = shift @ARGV;
my $image = read_image($color, $text);
open RAW, '>text.pl.bork.raw';
print RAW $image;
close RAW;
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

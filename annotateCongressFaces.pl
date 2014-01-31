#/usr/bin/perl -w

use strict;

use Cwd 'realpath';
use Switch;
use File::Find;
use File::Basename;
use File::Path;
use File::Spec;
use FindBin qw($Bin);
use List::MoreUtils qw( minmax );
use List::MoreUtils qw(firstidx);

my $usage = qq{
  Usage: annotateCongressFaces.pl
 };

my $congressDir = "/Users/ntustison/Desktop/Congress/";
my $congressOutputDir = "/Users/ntustison/Desktop/CongressAnnotate/";

my @images = <${congressDir}/*.nii.gz>;
for( my $i = 0; $i < @images; $i++ )
  {
  print "$images[$i]\n";
  my ( $filename, $directories, $suffix ) = fileparse( $images[$i], ".nii.gz" );

  my $annotation = "${congressOutputDir}/${filename}X.nii.gz";
  my $annotationAffine = "${congressOutputDir}/${filename}XAffine.txt";
  my $annotationWarped = "${congressOutputDir}/${filename}Warped.nii.gz";
  if( ! -e $annotation )
    {
    system( "/Applications/ITK-SNAP.app/Contents/MacOS/InsightSNAP -g $images[$i]" );
    `mv x.nii.gz $annotation`;
    }

#   my @out = `LabelGeometryMeasures 2 $annotation`;
#   my @centroidsX = ();
#   my @centroidsY = ();
#   for( my $j = 1; $j < @out; $j++ )
#     {
#     chomp( $out[$j] );
#     ( my $line = $out[$j] ) =~ s/,\ /,/g;
#     my @tokens = split( ' ', $line );
#
#     my $centroid = ${tokens[6]};
#     $centroid =~ s/\[//;
#     $centroid =~ s/\]//;
#     my @centroids = split( ',', $centroid );
#
#     push( @centroidsX, $centroids[0] );
#     push( @centroidsY, $centroids[1] );
#     }
#
#   my @newLabels = ();
#   my @found = (0) x 4;
#
#   my ( $minX, $maxX ) = minmax @centroidsX;
#   # left eye = 2
#   my $index = firstidx { $_ eq $minX } @centroidsX;
#   $newLabels[$index] = 2;
#   $found[$index] = 1;
#
#   print "X: $index -> $minX\n";
#
#   # right eye = 1
#   $index = firstidx { $_ eq $maxX } @centroidsX;
#   $newLabels[$index] = 1;
#   $found[$index] = 1;
#
#   # mouth = 4
#   my ( $minY, $maxY ) = minmax @centroidsY;
#   $index = firstidx { $_ eq $minY } @centroidsY;
#   $newLabels[$index] = 4;
#   $found[$index] = 1;
#
#   # nose = 3
#   for( my $j = 0; $j < @found; $j++ )
#     {
#     if( $found[$j] == 0 )
#       {
#       $newLabels[$j] = 3;
#       last;
#       }
#     }
#   print "@newLabels\n";
#   print "@centroidsX\n";
#
#   my $newLabelsString = join( 'x', @newLabels );
#   `UnaryOperateImage 2 $annotation r 0 $annotation 1x2x3x4 $newLabelsString`;

  `ANTSUseLandmarkImagesToGetAffineTransform CongressAnnotate/mean.nii.gz $annotation affine $annotationAffine`;
  open( FILE, "<${annotationAffine}" );
  my @fileContents = <FILE>;
  close( FILE );

  $fileContents[2] =~ s/_3_3/_2_2/;
  chomp( $fileContents[3] );
  my @parameters = split( ' ', $fileContents[3] );
  my @parameters2D = ( $parameters[0], $parameters[1], $parameters[2],
                                       $parameters[4], $parameters[5],
                                       $parameters[10], $parameters[11] );
  $fileContents[3] = "@parameters2D\n";

  @parameters = split( ' ', $fileContents[4] );
  @parameters2D = ( $parameters[0], $parameters[1], $parameters[2] );
  $fileContents[4] = "@parameters2D\n";

  open( FILE, ">${annotationAffine}" );
  print FILE "@fileContents";
  close( FILE );

  my @args = ( 'antsApplyTransforms', '-d', 2,
                                      '-o', $annotationWarped,
                                      '-i', $images[$i],
                                      '-r', 'CongressAnnotate/mean.nii.gz',
                                      '-n', 'BSpline',
                                      '-t', $annotationAffine );
  system( @args ) == 0 || die "Error\n";
  }

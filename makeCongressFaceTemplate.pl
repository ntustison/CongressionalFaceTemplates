#/usr/bin/perl -w

use strict;

use Cwd 'realpath';
use Switch;
use File::Find;
use File::Basename;
use File::Path;
use File::Spec;
use FindBin qw($Bin);

my $usage = qq{
  Usage: makeCongressFaceTemplate.pl <outputDir> <key1=value1> <key2=value2>

  example: makeCongressFaceTemplate.pl ./TemplateSenateDemocrats/ party=D title=Sen
 };

my $baseDir = "/Users/ntustison/Data/Public/CongressionalFaceTemplates/";
my $facesDir = "${baseDir}/Warped/";
my $file = "${baseDir}/legislators.csv";

open( FILE, "<$file" ) or die "$file: $!";
my @csvContents = <FILE>;
close( FILE );


my $outputDir = $ARGV[0];
print "$outputDir\n";
if( ! -e $outputDir )
  {
  mkpath( $outputDir ) || die "make path\n";
  }

# get key/value pairs

my %hash = ();


for( my $i = 1; $i < @ARGV; $i++ )
  {
  my @tokens = split( '=', $ARGV[$i] );

  my $key = $tokens[0];
  my $value = $tokens[1];

  $hash{ $key } = $value;
  }

my @keyNames = keys %hash;

# get column indices
my @rownames = split( ',', $csvContents[0] );
my @indices = ();
for( my $i = 0; $i < @rownames; $i++ )
  {
  for( my $j = 0; $j < @keyNames; $j++ )
    {
    if( $keyNames[$j] =~ m/${rownames[$i]}/ )
      {
      push( @indices, $i );
      }
    }
  }
@indices = sort { $a <=> $b } @indices;
for( my $i = 0; $i < @indices; $i++ )
  {
  $keyNames[$i] = $rownames[${indices[$i]}];
  }

my @images = ();
for( my $i = 1; $i < @csvContents; $i++ )
  {
  my @tokens = split( ',', $csvContents[$i] );

  my $bioId = $tokens[16];
  my $isMatch = 1;

  for( my $j = 0; $j < @indices; $j++ )
    {
    my $value = $hash{ $keyNames[$j] };

    if( $tokens[${indices[$j]}] !~ m/${value}/ )
      {
      $isMatch = 0;
      last;
      }
    }
  if( $isMatch && -e "${facesDir}/${bioId}Warped.nii.gz" )
    {
    push( @images, "${facesDir}/${bioId}Warped.nii.gz", "${facesDir}/${bioId}WarpedLaplacian.nii.gz" );
    }
  }

#############################################################
#
#  Now construct the template
#
#############################################################

`AverageImages 2 ${outputDir}/affineAverage.nii.gz 0 @images`;
`RescaleImageIntensity 2 ${outputDir}/affineAverage.nii.gz ${outputDir}/affineAverage.nii.gz 0 1000`;
`ConvertImage 2 ${outputDir}/affineAverage.nii.gz ${outputDir}/affineAverage.png 2`;

my @args = ( "antsMultivariateTemplateConstruction2.sh",
             '-d', 2,
             '-o', "${outputDir}/T_",
             '-i', 6,
             '-g', 0.25,
             '-j', 8,
             '-c', 2,
             '-k', 2,
             '-w', '0.25x1.0',
             '-f', '8x4x2x1',
             '-s', '3x2x1x0vox',
             '-q', '100x75x50x20',
             '-n', 0,
             '-r', 0,
             '-l', 0,
             '-m', 'CC[1]',
             '-t', 'SyN[0.1,3,0]',
             @images );

print "@args\n";
system( @args ) == 0 || die "Error: template building.\n";

module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-svgstore');

  grunt.initConfig({
    svg2png: {
      all: {
        // specify files in array format with multiple src-dest mapping
        files: [
          // rasterize all SVG files in "img" and its subdirectories to "img/png"
          { cwd: 'source/assets/img/svgs/', src: ['*.svg'], dest: 'source/assets/img/svgs/_fallback' }
        ]
      }
    },

    svgstore: {
      options: {
        prefix : 'shape-', // This will prefix each ID
        // fixedSizeVersion: {
        //   width: 75,
        //   height: 75,
        //   suffix: '-fixed',
        //   maxDigits: {
        //     translation: 4,
        //     scale: 4,
        //   },
        // },
        svg: { // will add and overide the the default xmlns="http://www.w3.org/2000/svg" attribute to the resulting SVG
          style: "display:none;"
        }
      },
      default: {
        files: {
          "source/assets/img/shapes.svg":["source/assets/img/svgs/*.svg"]
        }
      }
    },

    "azure-cdn-deploy": {
      app: {
        options: {
          containerName: 'framework-assets',
          containerOptions: {publicAccessLevel: 'blob'},
          folder : '',
          serviceOptions: ['interfacecampaigns', 'cfiEpxphPrJzIsI8bL5a5hCSF5Rn1zFVWPcm3Z323IFA+dbmpr9xgSHm1hXHz24x4d+4Z5tU/Ri+70VL7Lh09g=='],
          zip: false,
          deleteExistingBlobs: true,
          concurrentUploadThreads: 10,
          testRun: false
        },
        src: [
          'css/*.css',
          'js/*.js',
          'js/libs/*.js',
          'js/json/*.json',
          'img/*.jpg',
          'img/*.png',
          'img/*.svg',
          'img/svg/*.svg',
          'bower/*.js',
          'bower/*.css'
        ],
        cwd: 'build/framework-assets/'
      }
    }
  });
  
  grunt.registerTask('svg-convert', ['svg2png']);
  grunt.registerTask('svg', ['svgstore']);
  grunt.registerTask('deploy-cdn', ["azure-cdn-deploy"]);
};

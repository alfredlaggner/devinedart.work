'use strict';

var gulp = require('gulp'),
    watch = require('gulp-watch'),
    autoprefix = require('gulp-autoprefixer'),
    less = require('gulp-less'),
    minifyCSS = require('gulp-minify-css'),
    rename = require('gulp-rename'),
    concat = require('gulp-concat'),
    uglify = require('gulp-uglify'),
    gulpIgnore = require('gulp-ignore'),
    rigger = require('gulp-rigger'),
    imageop = require('gulp-image-optimization'),
    rimraf = require('rimraf'),
    browserSync = require("browser-sync"),
    reload = browserSync.reload;

var path = {
    clean: './build',

    build: { // production landing
        html: 'build/',
        js: 'build/js/',
        css: 'build/css/',
        img: 'build/img/',
        imgContent: 'build/content/',
        fonts: 'build/fonts/'
    },
    lpSrc: { // development landing
        html: 'src/*.html',
        js: 'src/js/main.js',
        style: 'src/styles/themes/*.less',
        img: 'src/img/**/*.*',
        imgContent: 'src/content/**/*.*',
        fonts: 'src/fonts/**/*.*'
    },
    watch: { // watch landing
        html: 'src/**/*.html',
        js: 'src/js/**/*.js',
        style: 'src/styles/**/*.less',
        img: 'src/img/**/*.*',
        imgContent: 'src/content/**/*.*',
        fonts: 'src/fonts/**/*.*'
    }

};

/* =====================================================
    SERVER
    ===================================================== */

var config = {
    server: {
        baseDir: "./build"
    },
    tunnel: true,
    host: 'localhost',
    port: 9000,
    logPrefix: "Frontend",
    watchTask: true
};

gulp.task('webserver', function () {
    browserSync(config);
});

/* =====================================================
    CLEAN PRODUCTION
    ===================================================== */

gulp.task('clean', function (cb) {
    rimraf(path.clean, cb);
});


/* =====================================================
    DEFAULT TASK
    ===================================================== */

gulp.task('default', ['build', 'webserver', 'watch']);


/* =====================================================
    LANDING
    ===================================================== */

// Server
var configLp = {
    server: {
        baseDir: "./build"
    },
    tunnel: true,
    host: 'localhost',
    port: 9000,
    logPrefix: "Landing",
    watchTask: true
};

gulp.task('server', function () {
    browserSync(configLp);
});

// HTML
gulp.task('html:build', function () {
    return gulp.src(path.lpSrc.html)
        .pipe(rigger())
        .pipe(gulp.dest(path.build.html))
        .pipe(reload({stream: true}));
});


// JS
gulp.task('js:build', function () {
    return gulp.src(path.lpSrc.js)
        .pipe(rigger())
        .pipe(uglify())
        .pipe(gulp.dest(path.build.js))
        .pipe(reload({stream: true}));
});


// Styles
gulp.task('style:build', function () {
    gulp.src(path.lpSrc.style)
        .pipe(less())
        .pipe(autoprefix({
            browsers: ['last 30 versions', '> 1%', 'ie 8', 'ie 9'],
            cascade: true
        }))
        .pipe(minifyCSS())
        .pipe(gulp.dest(path.build.css))
        .pipe(reload({stream: true}));
});


// Images
gulp.task('image:build', function (cb) {
    gulp.src(path.lpSrc.img)
        .pipe(imageop({
            optimizationLevel: 5,
            progressive: true,
            interlaced: true
        }))
        .pipe(gulp.dest(path.build.img)).on('end', cb).on('error', cb);
});

gulp.task('imageCont:build', function (cb) {
    gulp.src(path.lpSrc.imgContent)
        .pipe(imageop({
            optimizationLevel: 5,
            progressive: true,
            interlaced: true
        }))
        .pipe(gulp.dest(path.build.imgContent)).on('end', cb).on('error', cb);
});


// Fonts
gulp.task('fonts:build', function() {
    gulp.src(path.lpSrc.fonts)
        .pipe(gulp.dest(path.build.fonts))
});


// Build Task
gulp.task('build', [
    'html:build',
    'fonts:build',
    'js:build',
    'style:build',
    'image:build',
    'imageCont:build'
]);


// Watch
gulp.task('watch', function(){
    watch([path.watch.html], function(event, cb) {
        gulp.start('html:build');
    });
    watch([path.watch.style], function(event, cb) {
        gulp.start('style:build');
    });
    watch([path.watch.js], function(event, cb) {
        gulp.start('js:build');
    });
    watch([path.watch.img], function(event, cb) {
        gulp.start('image:build');
    });
    watch([path.watch.imgContent], function(event, cb) {
        gulp.start('imageCont:build');
    });
    watch([path.watch.fonts], function(event, cb) {
        gulp.start('fonts:build');
    });
});

gulp.task('landing', ['build', 'server', 'watch']);

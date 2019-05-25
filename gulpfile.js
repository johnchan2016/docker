var gulp = require('gulp')
var minifyCss = require('gulp-minify-css')
var uglify = require('gulp-uglify')

// 定义源代码的目录和编译压缩后的目录
var src = './src'
var dist = './dist'

//编译全部scss 并压缩
function css() {
  return gulp.src(src + '/**/**/*.css')
    .pipe(minifyCss())
    .pipe(gulp.dest(dist))
}
// 编译全部js 并压缩
function js() {
  return gulp.src(src + '/**/*.js')
    .pipe(uglify())
    .pipe(gulp.dest(dist))
}

exports.default =  gulp.series( css, js );
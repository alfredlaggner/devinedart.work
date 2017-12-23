$(document).ready(function(){

/* ==========================================================================
    Fixed Menu
    ========================================================================== */

    function fixedHeader() {
        var header = $('.site-header');

        if ( $(document).scrollTop() > 28 ) {
            header.addClass('fixed');
        } else {
            header.removeClass('fixed');
        }
    }

    fixedHeader();

    $(window).scroll(function () {
        fixedHeader();
    });

/* ==========================================================================
    Mobile Menu
    ========================================================================== */

    $('.site-header').each(function(){
       var parent = $(this),
           burger = parent.find('.burger'),
           className = 'opened';

        burger.click(function(){
           if (!parent.hasClass(className)) {
               parent.addClass(className);
           } else {
               parent.removeClass(className);
           }
        });
    });

/* ==========================================================================
    Page Nav
    ========================================================================== */

    $('#page-nav').singlePageNav({
        offset: $('.site-header').outerHeight(),
        filter: ':not(.external)',
        updateHash: true,
        speed: 1000,
        beforeStart: function() {
            $('.site-header').removeClass('opened');
        },
        onComplete: function() {
            // actions
        }
    });

/* ==========================================================================
    Card
    ========================================================================== */

    $('.card-item').each(function(){
       $(this).css('backgroundImage', 'url(' + $(this).find('.card-item-pic').attr('src') + ')');
    });

/* ==========================================================================
    Video
    ========================================================================== */

    $('.video-container').each(function(){
        var parent = $(this),
            videoFrame = parent.find('iframe'),
            preview = parent.find('.video-preview');

        preview
            .css('backgroundImage', 'url(' + $(this).find('.poster').attr('src') + ')')
            .click(function() {
                videoFrame.attr('src', videoFrame.attr('src') + '?autoplay=1');
                preview.fadeOut(500);
            });
    });

/* ==========================================================================
    Price
    ========================================================================== */

    $('.price-block').matchHeight();


/*  ========================================================================== */

});





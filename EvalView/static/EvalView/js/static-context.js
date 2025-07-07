$(document).ready(function() {
    $(document).on('click', '.toggle-context', function(e) {
        e.preventDefault(); // Prevent the link from navigating

        const targetId = $(this).data('target');
        const $targetContent = $('#' + targetId);

        // Toggle visibility of the content with a smooth animation
        $targetContent.slideToggle('fast');

        // Change the link text between (show) and (hide)
        const linkText = $(this).text();
        if (linkText.includes('(show)')) {
            $(this).text('(hide)');
        } else {
            $(this).text('(show)');
        }
    });
});
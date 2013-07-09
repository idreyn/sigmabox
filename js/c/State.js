function State() {

}

State.prototype.subscribe = function(element) {
	$(element).addClass('state-subscribed');
}

State.prototype.refresh = function() {
	$('.state-subscribed').trigger('update-state');
}
/*******************************************************************************
 * Copyright (c) 2015 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/

define(['xtext/services/XtextService', 'jquery'], function(XtextService, jQuery) {
	
	/**
	 * Service class for hover information.
	 */
	function HoverService(serverUrl, resourceId, updateService) {
		this.initialize(serverUrl, resourceId, 'hover', updateService);
	};

	HoverService.prototype = new XtextService();
	HoverService.prototype.computeHoverInfo = HoverService.prototype.invoke;

	HoverService.prototype._initServerData = function(serverData, editorContext, params) {
		if (params.offset)
			serverData.caretOffset = params.offset;
		else
			serverData.caretOffset = editorContext.getCaretOffset();
	};
	
	HoverService.prototype._getSuccessCallback = function(editorContext, params, deferred) {
		var delay = params.mouseHoverDelay;
		if (!delay)
			delay = 500;
		var showTime = new Date().getTime() + delay;
		return function(result) {
			if (result && !result.conflict) {
				var remainingTimeout = Math.max(0, showTime - new Date().getTime());
				setTimeout(function() {
					if (result.stateId !== undefined && result.stateId != editorContext.getServerState().stateId) 
						deferred.reject();
					else
						deferred.resolve(result);
				}, remainingTimeout);
			} else {
				deferred.reject();
			}
		};
	};
	
	return HoverService;
});
/*******************************************************************************
 * Copyright (c) 2015 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/

define(['xtext/services/XtextService', 'jquery'], function(XtextService, jQuery) {
	
	/**
	 * Service class for marking occurrences.
	 */
	function OccurrencesService(serverUrl, resourceId, updateService) {
		this.initialize(serverUrl, resourceId, 'occurrences', updateService);
	};

	OccurrencesService.prototype = new XtextService();
	OccurrencesService.prototype.getOccurrences = OccurrencesService.prototype.invoke;

	OccurrencesService.prototype._initServerData = function(serverData, editorContext, params) {
		if (params.offset)
			serverData.caretOffset = params.offset;
		else
			serverData.caretOffset = editorContext.getCaretOffset();
	};
	
	OccurrencesService.prototype._getSuccessCallback = function(editorContext, params, deferred) {
		return function(result) {
			if (result && !result.conflict 
					&& (result.stateId === undefined || result.stateId == editorContext.getServerState().stateId)) 
				deferred.resolve(result);
			else 
				deferred.reject();
		}
	}

	return OccurrencesService;
});
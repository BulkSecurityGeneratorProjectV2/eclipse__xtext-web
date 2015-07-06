/*******************************************************************************
 * Copyright (c) 2015 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtext.web.server.contentassist

import com.google.inject.Inject
import com.google.inject.Provider
import com.google.inject.Singleton
import java.util.HashSet
import java.util.List
import java.util.concurrent.ExecutorService
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistEntry
import org.eclipse.xtext.ide.editor.contentassist.IIdeContentProposalAcceptor
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalProvider
import org.eclipse.xtext.ide.editor.contentassist.antlr.ContentAssistContextFactory
import org.eclipse.xtext.util.ITextRegion
import org.eclipse.xtext.web.server.InvalidRequestException
import org.eclipse.xtext.web.server.model.XtextWebDocumentAccess

/**
 * Service class for content assist proposals.
 */
@Singleton
class ContentAssistService {
	
	public static val DEFAULT_PROPOSALS_LIMIT = 1000
	
	@Inject Provider<ContentAssistContextFactory> contextFactoryProvider
	
	@Inject IdeContentProposalProvider proposalProvider
	
	@Inject ExecutorService executorService
	
	/**
	 * Create content assist proposals at the given caret offset. This document read operation
	 * is scheduled with higher priority, so currently running operations may be canceled.
	 * The document processing is rescheduled as background work afterwards.
	 */
	def ContentAssistResult createProposals(XtextWebDocumentAccess document, ITextRegion selection, int offset, int proposalsLimit)
			throws InvalidRequestException {
		val contextFactory = contextFactoryProvider.get() => [it.pool = executorService]
		val stateIdWrapper = ArrayLiterals.newArrayOfSize(1)
		val contexts = document.priorityReadOnly([ it, cancelIndicator |
			stateIdWrapper.set(0, stateId)
			contextFactory.create(text, selection, offset, resource)
		], null)
		return createProposals(contexts, stateIdWrapper.get(0), proposalsLimit)
	}
	
	/**
	 * Apply a text update and then create content assist proposals. This document read operation
	 * is scheduled with higher priority, so currently running operations may be canceled.
	 * The document processing is rescheduled as background work afterwards.
	 */
	def ContentAssistResult createProposalsWithUpdate(XtextWebDocumentAccess document, String deltaText, int deltaOffset,
			int deltaReplaceLength, ITextRegion textSelection, int caretOffset, int proposalsLimit)
			throws InvalidRequestException {
		val contextFactory = contextFactoryProvider.get() => [it.pool = executorService]
		val stateIdWrapper = ArrayLiterals.newArrayOfSize(1)
		val contexts = document.modify [ it, cancelIndicator |
			dirty = true
			createNewStateId()
			stateIdWrapper.set(0, stateId)
			updateText(deltaText, deltaOffset, deltaReplaceLength)
			contextFactory.create(text, textSelection, caretOffset, resource)
		]
		return createProposals(contexts, stateIdWrapper.get(0), proposalsLimit)
	}
	
	/**
	 * Invoke the proposal provider and put the results into a {@link ContentAssistResult} object.
	 */
	protected def createProposals(List<ContentAssistContext> contexts, String stateId, int proposalsLimit) {
		val result = new ContentAssistResult
		result.stateId = stateId
		if (!contexts.empty) {
			val proposals = new HashSet<Pair<Integer, ContentAssistEntry>>
			val acceptor = new IIdeContentProposalAcceptor {
				override accept(ContentAssistEntry entry, int priority) {
					proposals.add(priority -> entry)
				}
				override canAcceptMoreProposals() {
					proposals.size < proposalsLimit
				}
			}
			
			proposalProvider.createProposals(contexts, acceptor)
			
			result.entries.addAll(proposals.sortWith[p1, p2 |
				val prioResult = p2.key.compareTo(p1.key)
				if (prioResult != 0)
					return prioResult
				val v1 = p1.value
				val v2 = p2.value
				if (v1.label !== null && v2.label !== null)
					return v1.label.compareTo(v2.label)
				else if (v1.label !== null)
					return v1.label.compareTo(v2.proposal)
				else if (v2.label !== null)
					return v1.proposal.compareTo(v2.label)
				else
					return v1.proposal.compareTo(v2.proposal)
			].map[value])
		}
		return result
	}
	
}
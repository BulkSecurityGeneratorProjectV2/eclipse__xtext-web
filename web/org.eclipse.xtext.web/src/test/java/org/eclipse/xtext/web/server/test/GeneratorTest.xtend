/*******************************************************************************
 * Copyright (c) 2015 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtext.web.server.test

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.web.example.statemachine.StatemachineRuntimeModule
import org.eclipse.xtext.web.example.statemachine.statemachine.Statemachine
import org.eclipse.xtext.web.server.generator.GeneratorResult
import org.eclipse.xtext.web.server.test.GeneratorTest.Generator
import org.junit.Test

class GeneratorTest extends AbstractWebServerTest {
	
	static class Generator implements IGenerator {
		override doGenerate(Resource input, IFileSystemAccess fsa) {
			val statemachine = input.contents.filter(Statemachine).head
			fsa.generateFile('test.txt', '''
				�FOR state : statemachine.states SEPARATOR ','��state.name��ENDFOR�
			''')
		}
	}
	
	override protected getRuntimeModule() {
		new StatemachineRuntimeModule {
			override bindIGenerator() {
				Generator
			}
		}
	}
	
	@Test def testGenerateText() {
		val file = createFile('state foo end state bar end')
		val generate = getService(#{'requestType' -> 'generate', 'resource' -> file.name})
		assertFalse(generate.hasSideEffects)
		assertFalse(generate.hasTextInput)
		val result = generate.service.apply() as GeneratorResult
		val String expectedResult = '''
			GeneratorResult [
			  entries = ArrayList (
			    GeneratedDocument [
			      name = "test.txt"
			      contentType = "text/plain"
			      content = "foo,bar\n"
			    ]
			  )
			]'''
		assertEquals(expectedResult, result.toString)
	}
	
}
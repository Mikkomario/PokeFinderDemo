//
//  PokeAnnotation.swift
//  PokeFinder
//
//  Created by Mikko Hilpinen on 27.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

class PokeAnnotation: NSObject, MKAnnotation
{
	// TODO: Implement titles and pokemon data using pokedex code
	
	var coordinate: CLLocationCoordinate2D
	var pokemonId: Int
	var title: String?
	
	init(id: Int, coordinate: CLLocationCoordinate2D)
	{
		self.coordinate = coordinate
		self.pokemonId = id
		
		self.title = "Test pokemon \(id)"
	}
}

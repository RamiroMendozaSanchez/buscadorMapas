//
//  ViewController.swift
//  buscadorMapas
//
//  Created by Ramiro y Jennifer on 03/05/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UISearchBarDelegate, MKMapViewDelegate {

    @IBOutlet weak var buscadorSB: UISearchBar!
    @IBOutlet weak var MapaMK: MKMapView!
    
    var latitud: CLLocationDegrees?
    var longitud: CLLocationDegrees?
    var altitud: Double?
    
    //manager para hacer uso del GPS
    var manager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.delegate = self
        buscadorSB.delegate = self
        
        MapaMK.delegate = self
        
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        
        //mejorar la precision de la ubicacion
        manager.desiredAccuracy = kCLLocationAccuracyBest
        //Monitorea en todo momento la ubicacion
        manager.startUpdatingLocation()
        
    }
    
    
    //MARK: trazar la ruta
    func trazarRuta(coordenadasDestino: CLLocationCoordinate2D){
        guard let coordOrigen = manager.location?.coordinate else {return}
        //Crear un lugar de origen y destino
        let origenPlaceMark = MKPlacemark(coordinate: coordOrigen)
        let destinoPlaceMark = MKPlacemark(coordinate: coordenadasDestino)
        print("destino mark \(destinoPlaceMark)")
        //Crear un obj en mapKit ITEM
        let origenItem = MKMapItem(placemark: origenPlaceMark)
        let destinoItem = MKMapItem(placemark: destinoPlaceMark)
        
        //solicitud de ruta
        let solicitudDestino =  MKDirections.Request()
        solicitudDestino.source = origenItem
        solicitudDestino.destination = destinoItem
        //como se va a viajar
        solicitudDestino.transportType = .automobile
        solicitudDestino.requestsAlternateRoutes = true
        
        let direcciones = MKDirections(request: solicitudDestino)
        direcciones.calculate { (respuesta, error) in
            //variable segura
            guard let respuestaSegura = respuesta else {
                if let error = error {
                    print("Error al calcular la ruta \(error.localizedDescription)")
                }
                return
            }
            //si tuvo una respuesta
            print(respuestaSegura.routes.count)
            let ruta = respuestaSegura.routes[0]
            //Agregar una superposicion
            self.MapaMK.addOverlay(ruta.polyline)
            self.MapaMK.setVisibleMapRect(ruta.polyline.boundingMapRect, animated: true)
            
            //calcular la distancia
            let loc1 = CLLocation(latitude: self.latitud ?? 0, longitude: self.longitud ?? 0)
            let loc2 = CLLocation(latitude: destinoPlaceMark.coordinate.latitude, longitude: destinoPlaceMark.coordinate.longitude)
            let distancia = loc1.distance(from: loc2)
            let distanciaKms = distancia / 1000
            print("Distancia \(distanciaKms)")
            
            let alerta = UIAlertController(title: "Distancia", message: "La distancia es \(distanciaKms) KMs", preferredStyle: .alert)
            
            let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
            
            alerta.addAction(accionAceptar)
            self.present(alerta, animated: true)

            
            
        }
    }
    
    //metodo de ayuda para poder agregar la superposicion al mapa
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderizado = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderizado.strokeColor = .blue
        return renderizado
    }
    

    @IBAction func UbicacionButton(_ sender: UIBarButtonItem) {
        
        let alerta = UIAlertController(title: "Ubicacion", message: "Las coordenadas son: \(latitud  ?? 0) \(longitud ?? 0) \(altitud ?? 0.0)", preferredStyle: .alert)
        
        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        
        alerta.addAction(accionAceptar)
        present(alerta, animated: true)
        
        let localizacion = CLLocationCoordinate2DMake(latitud!, longitud!)
        
        let spanMapa = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        let region = MKCoordinateRegion(center: localizacion, span: spanMapa)
        
        MapaMK.setRegion(region, animated: true)
        MapaMK.showsUserLocation  = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Ubicacion encontrada!")
        //metodo para ocultar el teclado
        buscadorSB.resignFirstResponder()
        let geocoder = CLGeocoder()
        if let direccion = buscadorSB.text {
            geocoder.geocodeAddressString(direccion) { [self] (places: [CLPlacemark]?, error: Error?) in
                
                //crear el destino
                guard let destinoRuta = places?.first?.location else {return}
                
                
                if error == nil{
                    //Buscar la direccion en el mapa
                    let lugar = places?.first
                    let anotacion = MKPointAnnotation()
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    anotacion.title = direccion
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    let region = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    
                    self.MapaMK.setRegion(region, animated: true)
                    self.MapaMK.addAnnotation(anotacion)
                    self.MapaMK.selectAnnotation(anotacion, animated: true)
                    
                    //mandar llamar a trazar ruta
                    self.trazarRuta(coordenadasDestino: destinoRuta.coordinate)
                    
                }else{
                    print("Error al encontrar la direccion \(error?.localizedDescription)")
                }
            }
        }
    }
    
}

extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Numero de ubicaciones: \(locations.count)")
        
        guard let ubicacion = locations.first else {
            return
        }
        
        latitud = ubicacion.coordinate.latitude
        longitud = ubicacion.coordinate.longitude
        altitud = ubicacion.altitude
        print(ubicacion)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicacion: \(error.localizedDescription)")
        let alerta = UIAlertController(title: "Error", message: "Lugar no encontrado o no se obtuvo ubicacion", preferredStyle: .alert)
        
        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        
        alerta.addAction(accionAceptar)
        present(alerta, animated: true)
    }
}


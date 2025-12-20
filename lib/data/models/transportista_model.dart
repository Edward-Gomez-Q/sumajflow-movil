// lib/data/models/transportista_model.dart
class TransportistaModel {
  final String ci;
  final String fechaNacimiento;
  final String correo;
  final String contrasena;
  final String placaVehiculo;
  final String marcaVehiculo;
  final String modeloVehiculo;
  final String colorVehiculo;
  final double pesoTara;
  final double capacidadCarga;
  final String licenciaConducirUrl;
  final String categoriaLicencia;
  final String fechaVencimientoLicencia;

  TransportistaModel({
    required this.ci,
    required this.fechaNacimiento,
    required this.correo,
    required this.contrasena,
    required this.placaVehiculo,
    required this.marcaVehiculo,
    required this.modeloVehiculo,
    required this.colorVehiculo,
    required this.pesoTara,
    required this.capacidadCarga,
    required this.licenciaConducirUrl,
    required this.categoriaLicencia,
    required this.fechaVencimientoLicencia,
  });

  Map<String, dynamic> toJson() => {
    'ci': ci,
    'fechaNacimiento': fechaNacimiento,
    'correo': correo,
    'contrasena': contrasena,
    'placaVehiculo': placaVehiculo,
    'marcaVehiculo': marcaVehiculo,
    'modeloVehiculo': modeloVehiculo,
    'colorVehiculo': colorVehiculo,
    'pesoTara': pesoTara,
    'capacidadCarga': capacidadCarga,
    'licenciaConducirUrl': licenciaConducirUrl,
    'categoriaLicencia': categoriaLicencia,
    'fechaVencimientoLicencia': fechaVencimientoLicencia,
  };
}

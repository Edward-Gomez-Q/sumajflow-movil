// lib/data/models/perfil_models.dart

class PerfilModel {
  final UsuarioPerfilModel usuario;
  final PersonaPerfilModel persona;
  final String tipoUsuario;
  final TransportistaPerfilModel? transportista;

  PerfilModel({
    required this.usuario,
    required this.persona,
    required this.tipoUsuario,
    this.transportista,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      usuario: UsuarioPerfilModel.fromJson(json['usuario']),
      persona: PersonaPerfilModel.fromJson(json['persona']),
      tipoUsuario: json['tipoUsuario'],
      transportista: json['transportista'] != null
          ? TransportistaPerfilModel.fromJson(json['transportista'])
          : null,
    );
  }

  String get nombreCompleto {
    final partes = [
      persona.nombres,
      persona.primerApellido,
      persona.segundoApellido,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return partes.join(' ');
  }

  String get iniciales {
    final nombre = persona.nombres?.isNotEmpty == true
        ? persona.nombres![0]
        : '';
    final apellido = persona.primerApellido?.isNotEmpty == true
        ? persona.primerApellido![0]
        : '';
    return '$nombre$apellido'.toUpperCase();
  }
}

class UsuarioPerfilModel {
  final int id;
  final String correo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UsuarioPerfilModel({
    required this.id,
    required this.correo,
    this.createdAt,
    this.updatedAt,
  });

  factory UsuarioPerfilModel.fromJson(Map<String, dynamic> json) {
    return UsuarioPerfilModel(
      id: json['id'],
      correo: json['correo'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

class PersonaPerfilModel {
  final int id;
  final String? nombres;
  final String? primerApellido;
  final String? segundoApellido;
  final String? ci;
  final String? fechaNacimiento;
  final String? numeroCelular;
  final String? genero;
  final String? nacionalidad;
  final String? departamento;
  final String? provincia;
  final String? municipio;
  final String? direccion;

  PersonaPerfilModel({
    required this.id,
    this.nombres,
    this.primerApellido,
    this.segundoApellido,
    this.ci,
    this.fechaNacimiento,
    this.numeroCelular,
    this.genero,
    this.nacionalidad,
    this.departamento,
    this.provincia,
    this.municipio,
    this.direccion,
  });

  factory PersonaPerfilModel.fromJson(Map<String, dynamic> json) {
    return PersonaPerfilModel(
      id: json['id'],
      nombres: json['nombres'],
      primerApellido: json['primerApellido'],
      segundoApellido: json['segundoApellido'],
      ci: json['ci'],
      fechaNacimiento: json['fechaNacimiento'],
      numeroCelular: json['numeroCelular'],
      genero: json['genero'],
      nacionalidad: json['nacionalidad'],
      departamento: json['departamento'],
      provincia: json['provincia'],
      municipio: json['municipio'],
      direccion: json['direccion'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nombres': nombres,
    'primerApellido': primerApellido,
    'segundoApellido': segundoApellido,
    'ci': ci,
    'fechaNacimiento': fechaNacimiento,
    'numeroCelular': numeroCelular,
    'genero': genero,
    'nacionalidad': nacionalidad,
    'departamento': departamento,
    'provincia': provincia,
    'municipio': municipio,
    'direccion': direccion,
  };
}

class TransportistaPerfilModel {
  final int id;
  final String ci;
  final String? placaVehiculo;
  final String? tipoVehiculo;
  final String? marcaVehiculo;
  final String? modeloVehiculo;
  final int? anioVehiculo;
  final String? colorVehiculo;
  final double? capacidadCarga;
  final double? pesoTara;
  final String estado;

  // Datos de licencia
  final String? licenciaConducir;
  final String? categoriaLicencia;
  final String? fechaVencimientoLicencia;

  TransportistaPerfilModel({
    required this.id,
    required this.ci,
    this.placaVehiculo,
    this.tipoVehiculo,
    this.marcaVehiculo,
    this.modeloVehiculo,
    this.anioVehiculo,
    this.colorVehiculo,
    this.capacidadCarga,
    this.pesoTara,
    required this.estado,
    this.licenciaConducir,
    this.categoriaLicencia,
    this.fechaVencimientoLicencia,
  });

  factory TransportistaPerfilModel.fromJson(Map<String, dynamic> json) {
    return TransportistaPerfilModel(
      id: json['id'],
      ci: json['ci'],
      placaVehiculo: json['placaVehiculo'],
      tipoVehiculo: json['tipoVehiculo'],
      marcaVehiculo: json['marcaVehiculo'],
      modeloVehiculo: json['modeloVehiculo'],
      anioVehiculo: json['anioVehiculo'],
      colorVehiculo: json['colorVehiculo'],
      capacidadCarga: json['capacidadCarga']?.toDouble(),
      pesoTara: json['pesoTara']?.toDouble(),
      estado: json['estado'],
      licenciaConducir: json['licenciaConducir'],
      categoriaLicencia: json['categoriaLicencia'],
      fechaVencimientoLicencia: json['fechaVencimientoLicencia'],
    );
  }

  Map<String, dynamic> toJson() => {
    'colorVehiculo': colorVehiculo,
    'categoriaLicencia': categoriaLicencia,
    'fechaVencimientoLicencia': fechaVencimientoLicencia,
    'licenciaConducir': licenciaConducir,
  };
}

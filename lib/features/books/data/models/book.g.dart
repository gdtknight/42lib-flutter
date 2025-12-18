// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      isbn: json['isbn'] as String?,
      category: json['category'] as String,
      description: json['description'] as String?,
      publicationYear: json['publicationYear'] as int?,
      quantity: json['quantity'] as int,
      availableQuantity: json['availableQuantity'] as int,
      coverImageUrl: json['coverImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'isbn': instance.isbn,
      'category': instance.category,
      'description': instance.description,
      'publicationYear': instance.publicationYear,
      'quantity': instance.quantity,
      'availableQuantity': instance.availableQuantity,
      'coverImageUrl': instance.coverImageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

// lib/widgets/comment_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'comment_card.dart';

class CommentSection extends StatefulWidget {
  final String documentId; // Bisa ID tugas atau materi
  final String collectionPath; // contoh: 'tugas'

  const CommentSection({
    super.key,
    required this.documentId,
    required this.collectionPath,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _commentController = TextEditingController();
  final _authService = AuthService();
  bool _isPosting = false;

  Future<void> _postComment() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null || _commentController.text.trim().isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isPosting = true);

    try {
      final userModel = await _authService.getUserData(currentUser.uid);
      if (userModel == null) throw Exception("User data not found");

      await FirebaseFirestore.instance
          .collection(widget.collectionPath)
          .doc(widget.documentId)
          .collection('komentar')
          .add({
        'text': _commentController.text.trim(),
        'authorUid': currentUser.uid,
        'authorName': userModel.nama,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim komentar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diskusi & Tanya Jawab',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        // Form untuk menambah komentar
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Tulis komentar...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 8),
            _isPosting
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.indigo),
                    onPressed: _postComment,
                    iconSize: 30,
                  ),
          ],
        ),
        const SizedBox(height: 24),
        // Stream untuk menampilkan daftar komentar
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(widget.collectionPath)
              .doc(widget.documentId)
              .collection('komentar')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Jadilah yang pertama berkomentar!'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var commentData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return CommentCard(
                  authorName: commentData['authorName'] ?? 'Anonim',
                  text: commentData['text'] ?? '',
                  timestamp:
                      commentData['timestamp'] ?? Timestamp.now(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
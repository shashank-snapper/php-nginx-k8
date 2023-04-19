<?php

namespace App\Controller;

use App\Document\TestCollection;
use Doctrine\ODM\MongoDB\DocumentManager;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

class BaseController extends AbstractController
{
    #[Route(path: "/")]
    public function index(DocumentManager $dm)
    {
        try {
            $rec = new TestCollection();
            $rec->timestamp = new \DateTime();
            $dm->persist($rec);
            $dm->flush();
            return new JsonResponse(['status_code' => '200', 'response' => 'Ok']);
        } catch (\Exception $e) {
            return new JsonResponse(['status_code' => 500, 'response' => 'KO', 'message' => $e->getMessage()], 500);
        }
    }
}